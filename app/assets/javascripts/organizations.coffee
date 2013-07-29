$ ->
  if $('.organizations-show')[0] # only enable on organizatio nshow page
    $('.event').mouseenter ->
      $("[data-event-id=#{$(this).data('event-id')}] .event-title a").addClass('hover')
      $('#sidebar .sidebar-box').hide()
      $('#sidebar-event-details').html($(this).clone()).show()

    $('.event').mouseleave ->
      $("[data-event-id=#{$(this).data('event-id')}] .event-title a").removeClass('hover')
      $('#sidebar .sidebar-box').show()
      $('#sidebar-event-details').hide()
