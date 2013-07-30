$ ->
  if $('.venues-index')[0] # only enable on venue index page
    $('.show-all-venues a').click ->
      $('.venues-view').addClass('all')
      false

    $('.view-switcher a').click ->
      $('.view-switcher a').removeClass('selected')
      $(this).addClass('selected')
      $container = $('.venues-view')
      $container.removeClass('list map')
      $container.addClass($(this).data('view'));
      $.cookie('venues_view', $(this).data('view'), expires: 14, path: '/')
      $(window).resize()
      false

    $(window).resize ->
      if $('.venues-view').hasClass('map')
        $card = $('.venues-map')
        $card.height($(window).innerHeight() - $card.position().top - 30)
        $card.width($(window).innerWidth() - $card.position().left - 30)
        $('#google_map').height($card.innerHeight())
        if !window.google_map? then initialize_google_map_google_map()
        window.google_map.checkResize()
      false

    $(window).resize()
