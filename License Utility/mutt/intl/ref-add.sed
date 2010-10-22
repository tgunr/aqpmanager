/^# Packages using this file: / {
  s/# Packages using this file://
  ta
  :a
  s/ mutt / mutt /
  tb
  s/ $/ mutt /
  :b
  s/^/# Packages using this file:/
}
