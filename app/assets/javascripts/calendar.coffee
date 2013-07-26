$ ->
  if $('.events-index')[0] # only enable on event pages

    $('.show-more').click ->
      $(this).hide().siblings('.extra').removeClass('extra')
      $day = $(this).parent('.day')

      # expand height of first day of month so month divider css stays connected
      $d1 = $day.siblings('.day.d1') # only find first day if in same week
      if $day.outerHeight() > $d1.outerHeight()
        $d1.css('height', $day.outerHeight())

      false

    $('.view-switcher a').click ->
      $('.view-switcher a').removeClass('selected')
      $(this).addClass('selected')
      $container = $('.events-view')
      $container.removeClass('list calendar')
      $container.addClass($(this).data('view'));
      $.cookie('events_view', $(this).data('view'), expires: 14, path: '/')
      false

    $('.event').mouseenter ->
      height = $('#sidebar').outerHeight() - 42 # account for padding and border
      $('#sidebar-event-details').css('min-height', height).html($(this).clone()).show()

    $('.event').mouseleave ->
      $('#sidebar-event-details').hide()
