// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

$(document).ready(function() {
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
      success: function(msg) {
        alert("Data Saved: " + msg );
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
