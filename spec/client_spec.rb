# require 'whois_slacking/version'
require './lib/whois_slacking'
require 'spec_helper'
require 'moneta'
require 'date'
require 'byebug'

describe "json client" do 
  

  before do
    @store = Moneta.new(:File, :dir => 'moneta')
  end

  after do
    @store.delete(whois_key)
    @store.clear
    @store.close
    @store = nil
  end

  # project-task_id-user
  def whois_key
    "#{ENV['PIVOTAL_PROJECT_NAME']}-task_id-user"
  end

  def project_name 
    ENV["PIVOTAL_PROJECT_NAME"]
  end

  def slack_channel
    ENV["SLACK_CHANNEL"]
  end

  def project
    ENV["PIVOTAL_PROJECT_NAME"]
  end

  def task_id
    'task_id'
  end

  def task
    'task'
  end

  def user
    'user'
  end

  def current_state
    'started'
  end
 
  def accepted_dt
    DateTime.now 
  end

  def start_dt
    DateTime.now 
  end

  it "should connect to pivotal" do
    WhoIsSlacking::Pivotal.connect_to_pivotal
    expect(PivotalTracker::Client.connection.timeout).to eql ENV["PIVOTAL_TIMEOUT"].to_i
  end

  it "should get a pivotal project" do
    WhoIsSlacking::Pivotal.connect_to_pivotal
    WhoIsSlacking::Pivotal.pivotal_project(project_name)
    expect(WhoIsSlacking::Pivotal.pivotal_project(project_name).name).to eql project_name 
  end

  it "should get a pivotal project members" do
    WhoIsSlacking::Pivotal.connect_to_pivotal
    project_object = WhoIsSlacking::Pivotal.pivotal_project(project_name)
    expect(WhoIsSlacking::Pivotal.project_members(project_object).count).should be > 0 
  end

  it "should get a pivotal project stories" do
    WhoIsSlacking::Pivotal.connect_to_pivotal
    project_object = WhoIsSlacking::Pivotal.pivotal_project(project_name)
    expect(WhoIsSlacking::Pivotal.project_stories(project_object).count).to be > 0 
  end

  it "should create a whois_slacking key" do
    expect(WhoIsSlacking::DataTools.whois_key(project, task_id, user)).to eql whois_key
  end

  it "should save a project task" do
    WhoIsSlacking::DataTools.save_task(project, task_id, task, user, current_state, accepted_dt)
    expect(@store.key?(whois_key)).to eql true
  end

  it "should know the proper slack channel" do
    expect(WhoIsSlacking::SlackWrapper.slack_channel).to eql slack_channel
  end

  it "should be able to post to slack" do
    message = "This channel is worthy for testing only"
    expect(WhoIsSlacking::SlackWrapper.post_to_slack(message)["ok"]).to eql true 
  end

  it "should post to slack 'Today xx started xxx' when a non completed task exists in pivotal but not in the db" do
    expect(WhoIsSlacking::DataTools.save_task(project, task_id, task, user, current_state, accepted_dt)
      .fetch("message", nil).fetch("text", nil)) .to eql "Today user started task"
  end

  it "should post to slack 'Today xx completed xxx' when a completed task exists in pivotal but not in the db" do
    current_state = 'finished'
    expect(WhoIsSlacking::DataTools.save_task(project, task_id, task, user, current_state, accepted_dt)
      .fetch("message", nil).fetch("text", nil)) .to eql "Today user finished task"
  end

  def direct_save(start_dt = (DateTime.now - 1))
    accepted_at = accepted_at 
    created_dt = DateTime.now.to_s
    updated_dt = created_dt
    current_state = current_state 
    active = true
    message = nil 
    task_entity = {project: project, task_id: task_id, task: task, user: user, current_state: current_state, active: active, start_dt: start_dt, created_dt: created_dt, accepted_at: accepted_at, updated_dt: updated_dt}
    store = WhoIsSlacking::DataTools.whois_store
    mutex = Moneta::Mutex.new(store, 'moneta')
    mutex.synchronize do
      mkey = WhoIsSlacking::DataTools.whois_key(project, task_id, user)
      store[mkey] = task_entity 
    end
  end

  it "should post to slack 'xx has spent xx days working on xxx' when a non completed task exists in pivotal and in the db" do
    accepted_dt = DateTime.now - 1
    direct_save
    expect(WhoIsSlacking::DataTools.save_task(project, task_id, task, user, current_state, accepted_dt)
      .fetch("message", nil).fetch("text", nil)) .to eql "user has spent 1 days working on task"  
  end

  it "should post to slack 'xx has spent xx hours working on xxx' when a non completed task exists in pivotal and in the db and the days worked is less than 1" do
    start_dt = DateTime.now - 0.5
    direct_save(start_dt)
    expect(WhoIsSlacking::DataTools.save_task(project, task_id, task, user, current_state, accepted_dt)
      .fetch("message", nil).fetch("text", nil)) .to eql "user has spent 12 hours working on task"  
  end

  it "should run through all tasks for a project, sending a message into slack for each of them" do
    WhoIsSlacking::Pivotal.connect_to_pivotal
    project_object = WhoIsSlacking::Pivotal.pivotal_project(project_name)
    expect(WhoIsSlacking::Start.now.count).to eql WhoIsSlacking::Pivotal.project_stories(project_object).count 
  end
end

