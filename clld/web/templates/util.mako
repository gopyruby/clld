
<%def name="data(obj=None)">
    <% obj = obj or ctx %>
    % if obj.data:
    <dl>
	% for key, items in h.groupby(sorted(obj.data, key=lambda o: (o.ord, o.key)), lambda x: x.key):
	    % if not key.startswith('_'):  ## we respect a convention to mark "private" data
	    <dt>${key}</dt>
	        % for item in items:
	        <dd>${item.value}</dd>
	        % endfor
	    % endif
        % endfor
    </dl>
    % endif
</%def>

<%def name="files(obj=None)">
    <% obj = obj or ctx %>
    % if obj.files:
    <dl>
	% for key, items in h.groupby(sorted(obj.files, key=lambda o: (o.ord, o.name)), lambda x: x.name):
	    % if not key.startswith('_'):  ## we respect a convention to mark "private" data
	    <dt>${key}</dt>
	        % for item in items:
	        <dd>${item.file.name}</dd>  ## TODO: link to associated file!
	        % endfor
	    % endif
        % endfor
    </dl>
    % endif
</%def>

<%def name="tree_node_label(level, id, checked=True)">
    <input class="level${level} treeview" type="checkbox" id="${id}"${' checked="checked"' if checked else ''}>
    <label for="${id}">
	<i class="icon-chevron-${'down' if checked else 'right'}"> </i>
	${caller.body()}
    </label>
</%def>

<%def name="accordion_group(eid, parent, title=None, open=False)">
    <div class="accordion-group">
        <div class="accordion-heading">
            <a class="accordion-toggle" data-toggle="collapse" data-parent="#${parent}" href="#${eid}">
                ${title or caller.title()}
            </a>
        </div>
        <div id="${eid}" class="accordion-body collapse${' in' if open else ''}">
            <div class="accordion-inner">
                ${caller.body()}
            </div>
        </div>
    </div>
</%def>

<%def name="table(items, eid='table')">
    <table id="${eid}" class="table table-hover">
        <thead>
	    <tr>${caller.head()}</tr>
        </thead>
        <tbody>
            % for item in items:
	    <tr>${caller.body(item=item)}</tr>
            % endfor
        </tbody>
    </table>
    <script>
    $(document).ready(function() {
        $('#${eid}').dataTable({bLengthChange: false, bPaginate: false, bInfo: false});
    });
    </script>
</%def>

<%def name="well(title=None)">
    <div class="well well-small">
	% if title:
	<h3>${title}</h3>
	% endif
	${caller.body()}
    </div>
</%def>

<%def name="sentences(obj=None)">
    <% obj = obj or ctx %>
    <ol id="sentences-${obj.pk}">
        % for a in obj.sentence_assocs:
        <li>
            % if a.description:
            <p>${a.description}</p>
            % endif
            ${h.rendered_sentence(a.sentence)}
            % if a.sentence.references:
            <p>See ${h.linked_references(request, a.sentence)|n}</p>
            % endif
        </li>
        % endfor
    </ol>
    <script>
    $(document).ready(function() {
        $('#sentences-${obj.pk} .ttip').tooltip({placement: 'bottom', delay: {hide: 300}});
    });
    </script>
</%def>
