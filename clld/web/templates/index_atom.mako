<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
    <title>${ctx}</title>
    <link href="${request.url}"/>
    <updated>${h.datetime.datetime.now().isoformat()}</updated>
    <author>${request.dataset.name}</author>
    <id></id>
    % for item in ctx.get_query(limit=1000):
    <entry>
        <title>${item}</title>
        <link href="${request.resource_url(item)}"/>
        <id>${item.id}</id>
        <updated>${item.updated.isoformat()}</updated>
        % if item.description:
        <summary>${item.description}</summary>
        % endif
    </entry>
    % endfor
</feed>
