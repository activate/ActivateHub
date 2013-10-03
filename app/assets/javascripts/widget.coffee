#= require jquery
#= require jquery.cookie
#= require_self

$ ->
  if $('body.widget.events-index')[0] # only enable on event widget
    $('.view-switcher a').click ->
      $('.view-switcher a').removeClass('selected')
      $(this).addClass('selected')
      $container = $('.events-list')
      $container.removeClass('list calendar')
      $container.addClass($(this).data('view'));
      $.cookie('events_view', $(this).data('view'), expires: 14, path: '/')
      false


    $(window).scroll ->
      # keep event details below header and calendar switching elements
      top = $('.events-list').offset().top - $(window).scrollTop()
      $('#widget-event-details').css('top', if top > 10 then top else '10px')


    $('.event').mouseenter ->
      $this = $(this)
      $("[data-event-id=#{$this.data('event-id')}] .event-title a").addClass('hover')

      $detailsElem = $('#widget-event-details').html($this.clone())

      if $('.events-list').is('.list')
        # list view, description is always on the right
        $detailsElem.removeClass('pos-left').addClass('pos-right').show()
      else if $this.closest('.day').is('.wday4, .wday5, .wday6')
        # event on right-side of calendar, show on left
        $detailsElem.removeClass('pos-right').addClass('pos-left').show()
      else
        # event on left-side of calendar, show on right
        $detailsElem.removeClass('pos-left').addClass('pos-right').show()


    $('.event').mouseleave ->
      $("[data-event-id=#{$(this).data('event-id')}] .event-title a").removeClass('hover')
      $('#widget-event-details').hide()


  # trigger scroll event on page load to reposition fixed elements
  $(window).scroll()
