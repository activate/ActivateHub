$ ->
  if $('.organizations-show')[0] # only enable on organization show page
    $('.show-sources a').click ->
      $container = $('.organization-sources-container').show()
      $('html, body').animate
          scrollTop: $container.offset().top - $('#navbar').outerHeight()
        2000
      false
