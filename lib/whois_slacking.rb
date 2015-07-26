# Require the necessary files
%w[
  rubygems
  pivotal-tracker
  slack
  time_difference
  byebug
  typhoeus
  multi_xml
].each { |r| require r }

module WhoIsSlacking 

  MultiXml.parser = :nokogiri

  class Start
    # whois-slacking
    # -- get project name
    # -- get slack channel
    # -- get all users for the project
    # -- save tasks
    #   -- retrieve all tasks from pivotal for the project
    #   -- loop through tasks
    #   -- if task/username combo does not exist in db
    #     -- save project/task/user 
    #     -- save when task was started
    #     -- save who started task
    #     -- if task is not-completed in pivotal
    #       -- save status as status not-completed
    #       -- publish message task/user started today
    #         -- "Today Johnny started 'As a user I should be able to log in'"
    #     -- if task is completed in pivotal
    #       -- save status as status completed
    #       -- publish message task/user started today
    #         -- "Today Johnny completed 'As a user I should be able to log in'"
    #   -- if task/username combo exists and is not completed in db
    #     -- calculate how long (realtime) the task has been worked on in days (.5, 1.5 etc)
    #     -- update time on task
    #     -- save who started task
    #     -- publish message task/user/how long to slack 
    #       -- "Johnny has spent 2 days working on 'As a user I should be able to log in'"
    # -- pruning
    #   -- retrieve all tasks from db for the project
    #   -- retrieve all tasks from pivotal for the project
    #   -- loop through all tasks from db
    #     -- if task/user name combo does not exist in pivotal
    #       -- mark task/user name combo in db as deleted
    #         -- "Today Johnny gave up working on 'As a user I should be able to log in'"
    #     -- if task/user name combo is completed in pivotal but not completed in db
    #       -- mark task/user name combo in db as completed
    #         -- "Today Johnny completed 'As a user I should be able to log in'"
    def self.now 
      WhoIsSlacking::Pivotal.connect_to_pivotal
      project_object = WhoIsSlacking::Pivotal
        .pivotal_project( WhoIsSlacking::Pivotal.project_name)
      tasks = WhoIsSlacking::Pivotal.project_stories(project_object) 
      tasks.each do |task|
        if task.current_state != 'unstarted' && 
            task.owned_by && 
            task.current_state != 'restart' &&
            task.current_state != 'unestimated' &&
            task.current_state != 'unscheduled' &&
            task.current_state != 'accepted' 
          WhoIsSlacking::DataTools.save_task(project_object.name, task.id, task.name, task.owned_by, task.current_state, task.accepted_at )
        end
      end
    end

  end

  class Pivotal
    def self.connect_to_pivotal
      PivotalTracker::Client.token = ENV["PIVOTAL_TOKEN"]
      PivotalTracker::Client.timeout = ENV["PIVOTAL_TIMEOUT"].to_i
    end

    def self.project_name
      ENV["PIVOTAL_PROJECT_NAME"]
    end

    def self.pivotal_project(single_project_name=project_name)
      projects = PivotalTracker::Project.all 
      projects.find {|x| x.name == single_project_name}
    end

    def self.project_members(project_object)
      project_object.memberships.all
    end

    def self.project_stories(project_object)
      project_object.stories.all
    end

    def self.pivotal_users_by_project
    end

  end

  class SlackWrapper
    def self.slack_channel
      ENV["SLACK_CHANNEL"]
    end 

    def self.post_to_slack(message)
      Slack.configure { |config| config.token = ENV["SLACK_TOKEN"] }
      Slack.chat_postMessage channel: slack_channel, text: message 
    end
  end

  class DataTools; 
    attr_accessor :data_format
    attr_accessor :apikey

    def self.whois_store(store_type=nil)
      t = store_type.nil? ? ENV["WHOIS_DATA_STORE"] : store_type.to_s

      case t
      when "redis"
        url = ENV["REDISTOGO_URL"] || "redis://127.0.0.1:6379/"
        uri = URI.parse url 
        store = Moneta.new(:Redis, host: uri.host, port: uri.port, password: uri.password)
      else # also for "file"
        store = Moneta.new(:File, :dir => 'moneta')
      end 
    end 

    def self.save_task(project, task_id, task, user, current_state, accepted_at, options={})

      # dont use accepted_at
      accepted_at = accepted_at 
      created_dt = DateTime.now.to_s
      start_dt = DateTime.now.to_s
      updated_dt = created_dt
      current_state = current_state 
      active = true
      message = nil 
      task_entity = {project: project, task_id: task_id, task: task, user: user, current_state: current_state, active: active, start_dt: start_dt, created_dt: created_dt, accepted_at: accepted_at, updated_dt: updated_dt}
      # initialize datastore type
      store = whois_store
      mutex = Moneta::Mutex.new(store, 'moneta')
      mutex.synchronize do
        mkey = self.whois_key(project, task_id, user)
        entity_exists = store[mkey]

        if entity_exists && 
            entity_exists[:current_state] != 'finished' &&
            entity_exists[:current_state] != 'delivered' && 
            entity_exists[:current_state] != 'accepted' #   -- if task/username combo exists and is not delivered/finished in db
          #     -- calculate how long (realtime) the task has been worked on in days (.5, 1.5 etc)
          #     -- update time on task
          #     -- save who started task
          #     -- publish message task/user/how long to slack 
          #       -- "Johnny has spent 2 days working on 'As a user I should be able to log in'"
          # keep created at date 

          start_dt = entity_exists[:start_dt].to_datetime
          puts "start_dt in db was #{start_dt}"

          days_worked = TimeDifference.between(DateTime.now,  start_dt).in_days 
          if days_worked >= 1.0 
            message = "*#{user} has spent #{days_worked.to_i} days working on #{task}*"
          else # show hours instead
            # hours_worked = TimeDifference.between(DateTime.now,  start_dt).in_hours
            # message = "*#{user} has spent #{hours_worked.to_i} hours working on #{task}*"
            message = "*#{user} has spent less than a day working on #{task}*"
          end
          # keep the created dt and start_dt
          created_dt = entity_exists[:created_dt]
          start_dt = entity_exists[:start_dt].to_datetime
          task_entity["created_dt"] = created_dt
          task_entity["start_dt"] = start_dt.to_s
          puts "start_dt in db will be #{start_dt}"
          store[mkey] = task_entity 

        elsif entity_exists && entity_exists[:current_state] == 'delivered' && current_state == 'delivered'
          start_dt = entity_exists[:start_dt].to_datetime
          puts "start_dt in db for delivered state was #{start_dt}"

          days_worked = TimeDifference.between(DateTime.now,  start_dt).in_days 
          if days_worked >= 1.0 
            message = "*Task #{task} has been in a delivered state for #{days_worked.to_i} days*"
          else
            message = "*Task #{task} has been in a delivered state for less than a day*"
          end
        elsif entity_exists && entity_exists[:current_state] == 'finished' 
          # don't do anything if entity already exists as delivered
        else #   -- if task/username combo does not exist in db
          #     -- save project/task/user 
          #     -- save when task was started
          #     -- save who started task
          store[mkey] = task_entity 

          if current_state != "finished" #     -- if task is not-completed in pivotal and is not in db
            #       -- save status as status not-completed
            #       -- publish message task/user started today
            #         -- "Today Johnny started 'As a user I should be able to log in'"
            message = "*Now tracking #{user} as doing #{task}*"

          elsif current_state == "finished" #     -- if task is completed in pivotal and is not in db
            #       -- save status as status completed
            #       -- publish message task/user started today
            #         -- "Today Johnny completed 'As a user I should be able to log in'"
            message = "*Today #{user} finished #{task} and it is waiting to be delivered*"
          elsif current_state == "delivered" #     -- if task is completed in pivotal
            #       -- save status as status completed
            #       -- publish message task/user started today
            #         -- "Today Johnny completed 'As a user I should be able to log in'"
            message = "*Today #{user} delivered #{task} and it is waiting to be accepted*"
          end

        end
      end
      WhoIsSlacking::SlackWrapper.post_to_slack(message) if message
    end

    def self.whois_key(project, task, user)
      "#{project}-#{task}-#{user}"
    end

  end
end
