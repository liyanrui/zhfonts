zhfonts 是 [ConTeXt](https://wiki.contextgarden.net/Installation) (>= MkIV) 第三方模块，旨在实现中文字体支持和标点符号微排版，后者主要基于 ConTeXt 的两个 Lua 接口：

```lua
tasks.appendaction("processors","after", ...)
tasks.appendaction("finalizers", "after", ...)
```

zhfonts 模块的具体用法参见「[ConTeXt 蹊径](https://github.com/liyanrui/ConTeXt-notes/blob/main/ConTeXt-notes.pdf)」第 3 章和第 15 章。
