var force_repository_module = function() {
  var r = $('project_enabled_module_names_repository');
  if (r) {
    r.checked = true;
    r.readOnly = true;
  }
};
var toggle_project_scm_visibility = function() {
  setVisible('project_scm', ($('project_enabled_module_names_repository').checked == true));
};
