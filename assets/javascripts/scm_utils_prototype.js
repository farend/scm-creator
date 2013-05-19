var force_repository_module = function() {
  var r = $('project_enabled_module_names_repository');
  if (r) {
    r.checked = true;
    r.disable();
  }
};
var toggle_project_scm_visibility = function() {
  setVisible('project_scm', ($('project_enabled_module_names_repository').checked == true));
};
