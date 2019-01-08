# Dolphin 🐬 

> “kekkekekeke or whatever sound dolphins make” — [Robert Beekman](https://github.com/matsimitsu)

Dolphin is a microblogging tool that intelligently converts, splits and posts updates to Twitter, Mastodon and Github.

![A screenshot of a web interface that can post updates to Twitter, Mastodon, and Github.](https://updates.jeffkreeftmeijer.com/media/Screenshot%202019-01-01%20at%2015.21.30.png)

“Intelligently”, because:

1. It splits long updates into threads, so longer updates are posted to Twitter and Mastodon.
2. It stores your updates in a Github repository, allowing you to keep an archive of all your updates yourself.
3. It does not post replies to Tweets to Mastodon, and vice versa.
4. It does not post Mastodon mentions to Twitter, and vice versa.
5. It does not cross-link. If an update doesn’t fit on Twitter, it shouldn’t be posted there with a link to Mastodon.
6. It’s a dolphin.

## How?

By running it yourself. You’ll need to configure these environment variables to make everything work:

    # Basic authentication (optional)
    BASIC_AUTH_USERNAME
    BASIC_AUTH_PASSWORD

    # Github credentials
    GITHUB_USERNAME
    GITHUB_REPOSITORY
    GITHUB_ACCESS_TOKEN

    # Twitter credentials (optional)
    TWITTER_USERNAME
    TWITTER_CONSUMER_KEY
    TWITTER_CONSUMER_SECRET
    TWITTER_ACCESS_TOKEN
    TWITTER_TOKEN_SECRET

    # Mastodon credentials (optional)
    MASTODON_BASE_URL
    MASTODON_BEARER_TOKEN
