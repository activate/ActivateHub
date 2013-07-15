$ ->
  if $('.events_index')[0] # only enable on event pages
    $('<div>').addClass('event-summary box').appendTo('.sidebar').hide()

    $('.show-more').click ->
      $(this).hide()
      $(this).siblings('.extra').removeClass('extra')
      false

    $('.event').mouseenter ->
      $("[data-event-id=#{$(this).data('event-id')}] .event-title").addClass('hover')
      $("#list_filters").hide()
      $(".event-summary").html($(this).clone()).show()

    $('.event').mouseleave ->
      $("[data-event-id=#{$(this).data('event-id')}] .event-title").removeClass('hover')
      $(".event-summary").hide()
      $("#list_filters").show()

    $('.switch-list').click ->
      $('.calendar-container').removeClass('calendar-container').addClass('list-container')
      $('.view-switcher a').removeClass('selected')
      $(this).addClass('selected')
      $.cookie('events_view', 'list', expires: 14)
      false

    $('.switch-calendar').click ->
      $('.list-container').removeClass('list-container').addClass('calendar-container')
      $('.view-switcher a').removeClass('selected')
      $(this).addClass('selected')
      $.cookie('events_view', 'calendar', expires: 14)
      false

    $('.sidebar .show-more-actions').click ->
      $('.sidebar .description').hide()
      $('.sidebar .more-actions').show()
      $(this).hide()
      false

  $(window).resize ->
    # switch to calendar view if not mobile and no explicit preference
    if document.width > 820 and $.cookie('events_view') != 'list'
      $('.switch-calendar').click()
  $(window).trigger('resize')
