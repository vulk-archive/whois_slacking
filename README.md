Whois Slacking.
=================

This is a ruby library that integrates Pivotal Tracker and Slack.
The library will send a message into a slack channel for every uncompleted task in pivotal, saying how long
a user has spent on that task.
This library is meant to be run once a day, to assist with morning standups.

You will recieve these messages similar to these in slack using this gem
```
James has spent 2 days working on Student Admissions 

Johnny has spent 12 hours working on User authentication 
```

## Installation 

```
gem install whois_slacking 
```
Update the .env file with the proper tokens

Make the following call in a ruby file and call it in cron job that runs daily:
```
WhoIsSlacking::Start.now
```

## Contribution

Installation for contributors

 1. Ensure all tests pass by running ```rspec spec```
 2. Submit a pull request with your changes

Please write tests for any changes you make or we will have our way with you
 
## License

[The MIT License (MIT)](http://vulk.mit-license.org)

Copyright (c) 2014 Vulk <[wolfpack@vulk.co](mailto:wolfpack@vulk.co)>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
