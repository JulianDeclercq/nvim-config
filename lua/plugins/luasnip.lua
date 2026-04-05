local ls = require 'luasnip'

ls.add_snippets('all', {
  ls.snippet({
    trig = 'character',
    -- hide from autocomplete,
    -- so you'll have to either expand it through the trigger + expand keybind
    -- or find it through telescope
    hidden = true,
  }, {
    ls.text_node {
      '# CHARACTERNAME MOC',
      '## Tutorials',
      '## Anti',
      '## Misc',
    },
  }),
  ls.snippet({
    trig = 'combo',
    hidden = true,
  }, {
    ls.text_node {
      '```fight',
      'input:',
      'name: Combo',
      'damage: 1',
      'hits: 1',
      '```',
    },
  }),
})
