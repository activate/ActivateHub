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
      $container = $('.events-list')
      $container.removeClass('list calendar')
      $container.addClass($(this).data('view'));
      $.cookie('events_view', $(this).data('view'), expires: 14, path: '/')
      false


  if $('.events-index, .organizations-show, .venues-show')[0]

    $('.event').mouseenter ->
      $("[data-event-id=#{$(this).data('event-id')}] .event-title a").addClass('hover')
      $('#sidebar .sidebar-box:not(#sidebar-welcome)').hide()
      $navbar = $('#navbar'); $welcome = $('#sidebar-welcome')
      threshold = $welcome.offset().top + $welcome.outerHeight() - $navbar.outerHeight()
      position = if $(window).scrollTop() > threshold then 'fixed' else 'static'
      $('#sidebar-event-details').html($(this).clone()).css('position', position).show()

    $('.event').mouseleave ->
      $("[data-event-id=#{$(this).data('event-id')}] .event-title a").removeClass('hover')
      $('#sidebar .sidebar-box').show()
      $('#sidebar-event-details').hide()
