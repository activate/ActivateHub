#= require jquery
#= require jquery_ujs
#= require jquery.cookie
#= require events
#= require organizations
#= require venues
#= require sources
#= require_self

$ ->
  # mobile-specific behaviour
  if $(window).width() <= 820
    # move sidebar to bottom of page so it's still accessible
    $('#sidebar-welcome, #sidebar-event-details').hide()
    $('#sidebar').insertAfter('#main').show()

    # force user to list view if resolution not acceptable for calendar view
    $('.events-index .events-list').removeClass('calendar').addClass('list')
