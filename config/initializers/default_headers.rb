# Default headers to include in HTTP responses
Rails.application.config.action_dispatch.default_headers.delete('X-Frame-Options')
