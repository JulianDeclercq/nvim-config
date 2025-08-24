local ls = require 'luasnip'

return {
  ls.snippet('charactermock', {
    ls.text_node {
      '# CHARACTER MOC',
      '## Tutorials',
      '## Anti',
      '## Misc',
    },
  }),
}
