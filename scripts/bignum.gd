class_name BigNum
extends RefCounted
## Big number formatting: 1.24K, 3.8M, 2.1B, etc.

const SUFFIXES := ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]

static func fmt(v: float) -> String:
	if v < 1000.0:
		if v < 10.0 and v != floor(v):
			return "%.1f" % v
		return "%d" % int(v)
	var tier := 0
	var x := v
	while x >= 1000.0 and tier < SUFFIXES.size() - 1:
		x /= 1000.0
		tier += 1
	if x >= 100.0:
		return "%d%s" % [int(x), SUFFIXES[tier]]
	elif x >= 10.0:
		return "%.1f%s" % [x, SUFFIXES[tier]]
	else:
		return "%.2f%s" % [x, SUFFIXES[tier]]

static func fmt_time(sec: float) -> String:
	var s := int(sec)
	if s < 60:
		return "%ds" % s
	var m := s / 60
	if m < 60:
		return "%dm" % m
	var h := m / 60
	if h < 24:
		return "%dh" % h
	return "%dd" % (h / 24)
