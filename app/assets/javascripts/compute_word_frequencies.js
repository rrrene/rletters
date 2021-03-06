
$(document).on('change', 'select#job_params_ngram_method',
  function(event, data) {
    toggleVisAndDisabled('#single_controls');
    toggleVisAndDisabled('#ngram_controls');

    // If we've shown the single controls, then reset the sub-control
    // visibility, otherwise hide the sub-controls
    if ($('#single_controls').is(':visible')) {
      $('#job_params_word_method').change();
      $('#job_params_exclude_method').change();
    } else {
      hideAndDisable('#num_words_controls');
      hideAndDisable('#inclusion_list_controls');
      hideAndDisable('#exclude_common_controls');
      hideAndDisable('#exclude_list_controls');
    }
  });

$(document).on('change', 'select#job_params_block_method',
  function(event, data) {
    toggleVisAndDisabled('#count_controls');
    toggleVisAndDisabled('#blocks_controls');
  });

$(document).on('change', 'select#job_params_word_method',
  function(event, data) {
    var option = this.options[this.selectedIndex].value;

    if (option == 'count') {
      showAndEnable('#num_words_controls');
      hideAndDisable('#inclusion_list_controls');
    } else {
      hideAndDisable('#num_words_controls');
      showAndEnable('#inclusion_list_controls');
    }
  });

$(document).on('change', 'select#job_params_exclude_method',
  function(event, data) {
    var option = this.options[this.selectedIndex].value;

    if (option == 'common') {
      showAndEnable('#exclude_common_controls');
      hideAndDisable('#exclude_list_controls');
    } else if (option == 'list') {
      hideAndDisable('#exclude_common_controls');
      showAndEnable('#exclude_list_controls');
    } else {
      hideAndDisable('#exclude_common_controls');
      hideAndDisable('#exclude_list_controls');
    }
  });
