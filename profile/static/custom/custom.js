$([IPython.events]).on('notebook_loaded.Notebook', function(){
	// add here logic that should be run once per **notebook load**
	// (!= page load), like restarting a checkpoint

	var md = IPython.notebook.metadata
	if(md.language){
		console.log('language already defined and is :', md.language);
	} else {
		md.language = 'Perl' ;
		console.log('add metadata hint that language is perl...');
	}
});

$([IPython.events]).on('app_initialized.NotebookApp', function(){
	// add here logic that should be run once per **page load**

	IPython.CodeCell.options_default['cm_config']['mode'] = 'perl';

	CodeMirror.requireMode('perl', function(){
		cells = IPython.notebook.get_cells();
		for(var i in cells){
			c = cells[i];
			if (c.cell_type === 'code'){
				c.auto_highlight()
			}
		}
	});
});
