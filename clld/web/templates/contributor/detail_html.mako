<%inherit file="../${context.get('request').registry.settings.get('clld.app_template', 'app.mako')}"/>
<%namespace name="util" file="../util.mako"/>
<%! active_menu_item = "contributors" %>


<h2>${_('Contributor')} ${ctx.name}</h2>

% if ctx.description:
<p>${ctx.description}</p>
% endif

<dl>
    % if ctx.address:
    <dt>${_('Address:')}</dt>
    <dd>
        <address>
            <strong>${ctx.name}</strong><br>
            ${h.text2html(ctx.address)|n}
        </address>
    </dd>
    % endif
    % if ctx.url:
    <dt>${_('Web:')}</dt>
    <dd>${h.external_link(ctx.url)}</dd>
    % endif
    % if ctx.email:
    <dt>${_('Mail:')}</dt>
    <dd>${ctx.email.replace('@', '[at]')}</dd>
    % endif
    % for k, v in ctx.datadict().items():
    <dt>${k}</dt>
    <dd>${v}</dd>
    % endfor
</dl>

<h3>${_('Contributions')}</h3>
<ul>
    % for c in ctx.contribution_assocs:
    <li>${h.link(request, c.contribution)}</li>
    % endfor
</ul>