## CURL GET Request Spammer

Script to spam URL with GET requests using curl. Good for farming views on view-based counters

THIS IS NOT A DDoS PROGRAM & DON'T USE IT AS SUCH!

### Features

- Checks for internet connection
- Checks for needed packages
- Continuously requests website using `curl`
- Visits website in specified number of parallel processes (1-10)
- Suitable for lower-end systems
- By default limited to 1 second delay and max 10 parallel processes
- `curl` requests are randomized with rotation of `User-Agent`
- `curl` requests are unique with rotation of `X-Custom-Header`
- `curl` doesn't store session or cookies (filters non-IP rate limiting mechanisms)

### Necessary packages

- `curl`
- `parallel`
- `bc`

Before proceeding install them on your linux distro

Debian example: `sudo apt install curl parallel bc`


### Setup Guide (Linux)

- clone the repo<br />
`git clone https://github.com/BakirGracic/curl-get-request-spammer`

- 'cd' in the repo dir<br />
`cd curl-get-request-spammer`

- add execution permission<br />
`sudo chmod +x script.sh`

- execute the script<br />
`./script.sh`

- use `-s` or `--silent` argument to disable request statuses

- input script variables best suiting your needs
