// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults


// Adds replace function to jQuery
// Substitutes node with a new node
$.fn.replace = function(o) { return this.after(o).remove(); };

$(document).ready(function() {

  $('#add-to-favorites').click(addRadio);

  function addRadio() {
    var node = $(this);
    var radio = JSON.parse($(this).attr('name'));
    addRadioToFavorites(node, radio.id);
  }

  $('#remove-from-favorites').click(removeRadio);

  function removeRadio() {
    var node = $(this);
    var radio = JSON.parse($(this).attr('name'));
    removeRadioFromFavorites(node, radio.id);
  }

  function removeRadioFromFavorites(node, radio_id) {
    $.ajax({
      type: "GET",
      url: '/favorites/remove/' + radio_id,
      dataType: 'json',
      success: function(result) {
        var color = "green";
        var font_style = "italic";

        node.css('color', color)
          .css('font-style', font_style)
          .text("Radio removed from favorites");

        // Reset to original text
        setTimeout(function() {
          node.replace(createAddRadioToFavoritesNode(radio_id));
        }, 2000);
      }
    });
  }

  function createAddRadioToFavoritesNode(radio_id) {
    var result = $("<span id='add-to-favorites' name='{\"id\" : " + radio_id + "}'>[Add to favorites]</span>");
    result.click(addRadio);
    return result;
  }

  function addRadioToFavorites(node, radio_id) {
    $.ajax({
      type: "GET",
      url: '/favorites/add/' + radio_id,
      dataType: 'json',
      success: function(result) {
        // Save previous style
        var original_text = node.text();
        var original_css = {
          'color': node.css('color'),
          'font_style': node.css('font-style')
        }

        // Prepare styles and show resulting message
        var color = "green";
        var font_style = "italic";
        if (result.status == "ERROR") {
          color = "red";
        }
        node.css('color', color)
          .css('font-style', font_style)
          .text(result.notificationMsg);

        // Set remove from radios
        setTimeout(function() {
          node.replace(createRemoveFromFavoritesNode(radio_id));
        }, 2000);
      }
    });
  }

  function createRemoveFromFavoritesNode(radio_id) {
    var result = $("<span id='remove-from-favorites' name='{\"id\" : " + radio_id + "}'>[Remove from favorites]</span>");
    result.click(removeRadio);
    return result;
  }

  $('#radio-station-data-edit').click(function() {
    var node = $(this);
    var option = node.text();

    if (option == '[Edit]') {
      editRadioStation(node);
    } else {
      var toBeSaved = getRadioStationObject(node);
      var id = node.attr('name');
      saveRadioStation(id, toBeSaved);
    }

  });

  function saveRadioStation(id, radio) {
    $.ajax({
      type: "POST",
      url: '/radios/' + id + '.json',
      data: {_method:'PUT', radio: radio},
      dataType: 'json',
      success: function(result) {
        var radio_id = result.redirect_to;
        if (radio_id != undefined) {
          jump_to(radio_id) ;
        }
        $('#radio-station-data').animate({backgroundColor:"yellow"},  100);
        $('#radio-station-data').animate({backgroundColor:"#d3d3d3" },  1000);
      }
    });
  }

  function jump_to(radio_id) {
    var href = location.href;
    var target = href.substr(0, href.lastIndexOf("/") + 1) + radio_id;
    window.location = target;
  }

  function editRadioStation(node) {
    var website_url = $('#website-url > a').attr('href');
    var tag_list = $('#tag-list').text();
    var radio_url = $('#radio-url').text();

    $('#website-url').replaceWith('<input id="website-url" type="text" value="' + website_url + '"/>');
    $('#tag-list').replaceWith('<input id="tag-list" type="text" value="' + tag_list + '"/>');
    $('#radio-url').replaceWith('<input id="radio-url" type="text" value="' + radio_url + '"/>');

    node.text('[Save]');
  }

  function getRadioStationObject(node) {
    var website_url = $('#website-url').val();
    var tag_list = $('#tag-list').val();
    var radio_url = $('#radio-url').val();

    $('#website-url').replaceWith('<span id="website-url"><a href="' + website_url + '">' + website_url + '</a></span>');
    $('#tag-list').replaceWith('<span id="tag-list">' + tag_list + '</span>');
    $('#radio-url').replaceWith('<span id="radio-url">' + radio_url + '</span>');

    var result = {"website": website_url, "gender": tag_list, "url": radio_url};

    node.text('[Edit]');
    return result;
  }

});

function htmlEncode(value){
    return $('<div/>').text(value).html();
}
