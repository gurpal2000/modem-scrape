# modem-scrape
Example script to scrape TD-W9970 v2 and send to prometheus push gateway.
Every 15 secs it will post to the push gateway.
The modem is known to sometimes show an error, so there's retry logic.

Pre-req (deps): install jq, curl and base64 first

Scrape magic is in getStats()

Raise an issue(s) if you want to ask some questions about the code/technique. It's not commented.
