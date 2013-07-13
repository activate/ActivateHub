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
      false

    $('.switch-calendar').click ->
      $('.list-container').removeClass('list-container').addClass('calendar-container')
      $('.view-switcher a').removeClass('selected')
      $(this).addClass('selected')
      false

    $('.sidebar .show-more-actions').click ->
      $('.sidebar .description').hide()
      $('.sidebar .more-actions').show()
      $(this).hide()
      false

  $(window).resize ->
    if document.width <= 820
      $('.switch-list').click()
  $(window).trigger('resize')
