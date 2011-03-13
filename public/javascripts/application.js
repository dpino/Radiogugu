// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

$(document).ready(function() {

  $('#add-to-favorites').click(function() {
    addRadioToFavorites($(this));
  });

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

  function addRadioToFavorites(node) {
    var radio_id = node.attr('name');

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
          .text(result.msg);

        // Reset to original text
        setTimeout(function() {
          node.css('color', original_css.color)
            .css('font-style', original_css.font_style)
            .text(original_text);
        }, 2000);
      }
    });
  }


  function saveRadioStation(id, radio) {
    $.ajax({
      type: "POST",
      url: '/radios/' + id + '.json',
      data: {_method:'PUT', radio: radio},
      dataType: 'json',
      success: function(msg) {
        $('#radio-station-data').animate({backgroundColor:"yellow"},  100);
        $('#radio-station-data').animate({backgroundColor:"#d3d3d3" },  1000);
      }
    });
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
