**请按以下规则改**

| 字段                          | 允许的匹配                                                   | 禁止的匹配                                         |
| ----------------------------- | ------------------------------------------------------------ | -------------------------------------------------- |
| App 显示名                    | exact, prefix, substring, acronym-prefix, subsequence fuzzy  | 不允许对拼音进行subsequence fuzzy或substring fuzzy |
| Tag                           | exact, prefix, substring, pinyin-prefix, pinyin-initials-prefix,subsequence fuzzy,substring fuzzy | 不允许对拼音进行subsequence fuzzy或substring fuzzy |
| Note                          | exact, prefix, substring，subsequence fuzzy，中文原文直搜，允许对拼音进行 substring fuzzy ， | 不允许对拼音进行 subsequence fuzzy                 |
| Bundle Identifier             | exact, prefix                                                | substring fuzzy；subsequence fuzzy                 |
| 内部 bundle 名如 CFBundleName | exact, prefix                                                | substring fuzzy；subsequence fuzzy                 |

**5 条验收用例**

- 输入 sex 时，不应该再出现 News / Siri / FindMy / Stocks / Journal / Freeform / 无影云电脑
- 输入 不背、news、find、journal 这类真实前缀，仍然要正常命中
- 输入中文备注原文关键词，比如“新闻”“助手”“股票”，仍然可以通过 note 命中
- 输入备注中中文词的拼音前缀，比如备注含“压缩”时输入 yasuo，仍然可以通过 note 命中
- 不背单词 不应该再因为 LangEasyLexis 被 sex 这种短词带出来





subsequence fuzzy  按顺序跳跃找字母，找到就算

- 可以理解成：**用户输入的字符，只要按顺序出现在目标文本里，中间允许隔着别的字符，也算匹配。**
- 输入PS，就能匹配photoshop



 substring fuzzy 要求字符是**连续出现**--但是不要去从头开始

- 只要作为一段连续文本出现就算匹配，不管是不是从开头匹配的
- 输入shop，就能匹配photoshop
