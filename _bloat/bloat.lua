print("hello lua!")

local function readfile(name)
  local fh = assert(io.open(name))
  local data = assert(fh:read '*a')
  fh:close()
  return data
end

local function writefile(name, content)
  local fh = assert(io.open(name, 'w'))
  assert(fh:write(content))
  fh:close()
end

local function table_transpose(t)
  local r = {}
  for k, v in pairs(t) do
    r[v] = k
  end
  return r
end

local function main()
  local template = html.parse(readfile '_bloat/bloat.html')

  -- Render articles.
  for _, article in ipairs(articles) do

    -- Parse markdown article from disk into HTML.
    print("RENDERING " .. article.slug)
    local text = html.from_md(readfile(article.src))
    article.html = text

    -- Put the main text of the article in #content node in the template.
    local template = template:clone()
    -- FIXME: implement below:
    -- local date_tmpl = template:find('#content time'):clone()
    template:find('#content'):set_children(text)
    -- FIXME: implement below:
    -- date_tmpl:find('time'):set_text(datetime) -- see further down
    -- template:find('#content *'):insert_before(date_tmpl)

    -- Set title in the template based on <h1> tag in the article.
    local title = template:find 'html head title'
    local h1 = text:find 'h1'
    if h1 then
        title:set_text(h1:get_text())
    else
        title:set_text(article.slug)
    end
    title:add_text(' — scribbles by akavel')

    -- FIXME: fix relative links - strip .md etc.
    -- TODO: copy images, css

    -- Write filled template to disk.
    writefile('_html.out/'..article.slug, template:to_string())
  end

  -- Render index.
  -- Sort articles, newest first.
  table.sort(articles, function(a, b) return a.datetime > b.datetime end)
  local index = html.parse(readfile '_bloat/index.html')
  local list_slot = index:find '#articles'
  local art_tmpl = list_slot:eject_children()
  for _, art in ipairs(articles) do
    local tags = table_transpose(art.tags)
    if not tags._drafts then
      local art_tmpl = art_tmpl:clone()

      local title_slot = art_tmpl:find('h2 a')
      title_slot:set_children(art.html:find 'h1')
      title_slot:set_attr('href', art.slug)

      local datetime = art.datetime:gsub('(%d%d%d%d)(%d%d)(%d%d).*', '%1-%2-%3')
      art_tmpl:find('time'):set_text(datetime)

      local tag_tmpl = art_tmpl:find('ul'):eject_children()
      for _, tag in ipairs(art.tags) do
        -- print(tag_tmpl:to_string())
        tag_tmpl:find('li a'):set_text('@'..tag)
        tag_tmpl:find('li a'):set_attr('href', '@'..tag)
        art_tmpl:find('ul'):add_children(tag_tmpl)
      end

      list_slot:add_children(art_tmpl)
    end
  end
  writefile('_html.out/index.html', index:to_string())
end

main()
