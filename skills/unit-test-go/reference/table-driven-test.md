## 表驱动测试
> 适用于需要覆盖多组输入/输出场景的函数或方法。
> 使用 `tests := []struct{...}{...}` + `t.Run` 组织用例；每个 case 的 name 必须唯一且语义化。

### 示例：结构体类型的方法测试
```go

type Cities map[string]string

// GetCityName 获取城市中文名
func (s Cities) GetCityName(cityEn string) string {
    return s[strings.ToLower(cityEn)]
}

// TestUnitCities_GetCityName GetCityName UT
func TestUnitCities_GetCityName(t *testing.T) {
	citys := Cities{
		"paris":          "巴黎",
		"bad leonfelden": "巴特莱昂费尔登",
	}

	tests := []struct {
		name  string
		input string
		want  string
	}{
		{name: "大小写不敏感", input: "Paris", want: "巴黎"},
		{name: "包含空格", input: "Bad Leonfelden", want: "巴特莱昂费尔登"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := citys.GetCityName(tt.input); got != tt.want {
				t.Errorf("GetCityName() = %v, want %v", got, tt.want)
			}
		})
	}
}
```

### 示例：返回值为 map 的方法测试
```go
func TestUnit_competitorRepo_priorityRoster(t *testing.T) {
	tests := []struct {
		name string
		in   []*competitor.Competitor
		want map[string]*competitor.Competitor
	}{
		{
			name: "不同competitorID，都返回",
			in: []*competitor.Competitor{
				{BaseInfo: competitor.BaseInfo{CompetitorID: "player:111"}, PlayerExtra: competitor.PlayerExtra{InRoster: true}},
				{BaseInfo: competitor.BaseInfo{CompetitorID: "player:222"}, PlayerExtra: competitor.PlayerExtra{InRoster: false}},
			},
			want: map[string]*competitor.Competitor{
				"player:111": {BaseInfo: competitor.BaseInfo{CompetitorID: "player:111"}, PlayerExtra: competitor.PlayerExtra{InRoster: true}},
				"player:222": {BaseInfo: competitor.BaseInfo{CompetitorID: "player:222"}, PlayerExtra: competitor.PlayerExtra{InRoster: false}},
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			r := &competitorRepo{}
			got := r.priorityRoster(tt.in)
			assert.Equal(t, tt.want, got)
		})
	}
}
```

### 示例：多字段 want + wantExist 复合断言
```go

func TestUnit_tennisStats_aggregatePlayerStats(t *testing.T) {
	tests := []struct {
		name      string
		codes     []string
		stats     []*dmtStat.CompetitorStat
		want      map[string]map[string]float64
		wantExist map[string][]string
	}{
		{
			name:  "sum_stats_by_player_and_code",
			codes: []string{def.StatisticCodeAces, def.StatisticCodeDoubleFaults},
			stats: []*dmtStat.CompetitorStat{
				{
					Competitor: dmtStat.Competitor{ID: "p1"},
					StatMap: map[int32]dmtStat.QuarterStatMap{
						dmtStat.QuarterTotal: {
							def.StatisticCodeAces:         &entity.Stat{Val: "2"},
							def.StatisticCodeDoubleFaults: &entity.Stat{Val: "1"},
						},
					},
				},
				{
					Competitor: dmtStat.Competitor{ID: "p1"},
					StatMap: map[int32]dmtStat.QuarterStatMap{
						dmtStat.QuarterTotal: {
							def.StatisticCodeAces: &entity.Stat{Val: "3"},
						},
					},
				},
				{
					Competitor: dmtStat.Competitor{ID: "p2"},
					StatMap: map[int32]dmtStat.QuarterStatMap{
						dmtStat.QuarterTotal: {
							def.StatisticCodeAces: &entity.Stat{Val: "1"},
						},
					},
				},
			},
			want: map[string]map[string]float64{
				"p1": {
					def.StatisticCodeAces:         5,
					def.StatisticCodeDoubleFaults: 1,
				},
				"p2": {
					def.StatisticCodeAces: 1,
				},
			},
			wantExist: map[string][]string{
				"p1": {def.StatisticCodeAces, def.StatisticCodeDoubleFaults},
				"p2": {def.StatisticCodeAces},
			},
		},
		{
			name:  "missing_code_is_ignored",
			codes: []string{def.StatisticCodeAces},
			stats: []*dmtStat.CompetitorStat{
				{
					Competitor: dmtStat.Competitor{ID: "p1"},
					StatMap: map[int32]dmtStat.QuarterStatMap{
						dmtStat.QuarterTotal: {},
					},
				},
			},
			want:      map[string]map[string]float64{},
			wantExist: map[string][]string{},
		},
	}

	s := &tennisStats{}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := &genTennisStatsReq{stats: tt.stats}
			got := s.aggregatePlayerStats(req, tt.codes)
			assert.Equalf(t, tt.want, got, "aggregatePlayerStats(%v, %v)", req, tt.codes)
		})
	}
}



```

### 错误例子
> ❌ 错误原因：用手动嵌套迭代替代 `assert.Equal`，代码冗长且易漏字段。
> 当 `wantExist` 有但 `want` 没有的 key 时不会报错，存在漏测风险。
> 应使用 `assert.Equal(t, tt.want, got)` 一次性整体比较。
```go

func TestUnit_tennisStats_aggregatePlayerStats(t *testing.T) {
	tests := []struct {
		name      string
		codes     []string
		stats     []*dmtStat.CompetitorStat
		want      map[string]map[string]float64
		wantExist map[string][]string
	}{
		{
			name:  "sum_stats_by_player_and_code",
			codes: []string{def.StatisticCodeAces, def.StatisticCodeDoubleFaults},
			stats: []*dmtStat.CompetitorStat{
				{
					Competitor: dmtStat.Competitor{ID: "p1"},
					StatMap: map[int32]dmtStat.QuarterStatMap{
						dmtStat.QuarterTotal: {
							def.StatisticCodeAces:         &entity.Stat{Val: "2"},
							def.StatisticCodeDoubleFaults: &entity.Stat{Val: "1"},
						},
					},
				},
				{
					Competitor: dmtStat.Competitor{ID: "p1"},
					StatMap: map[int32]dmtStat.QuarterStatMap{
						dmtStat.QuarterTotal: {
							def.StatisticCodeAces: &entity.Stat{Val: "3"},
						},
					},
				},
				{
					Competitor: dmtStat.Competitor{ID: "p2"},
					StatMap: map[int32]dmtStat.QuarterStatMap{
						dmtStat.QuarterTotal: {
							def.StatisticCodeAces: &entity.Stat{Val: "1"},
						},
					},
				},
			},
			want: map[string]map[string]float64{
				"p1": {
					def.StatisticCodeAces:         5,
					def.StatisticCodeDoubleFaults: 1,
				},
				"p2": {
					def.StatisticCodeAces: 1,
				},
			},
			wantExist: map[string][]string{
				"p1": {def.StatisticCodeAces, def.StatisticCodeDoubleFaults},
				"p2": {def.StatisticCodeAces},
			},
		},
		{
			name:  "missing_code_is_ignored",
			codes: []string{def.StatisticCodeAces},
			stats: []*dmtStat.CompetitorStat{
				{
					Competitor: dmtStat.Competitor{ID: "p1"},
					StatMap: map[int32]dmtStat.QuarterStatMap{
						dmtStat.QuarterTotal: {},
					},
				},
			},
			want:      map[string]map[string]float64{},
			wantExist: map[string][]string{},
		},
	}

	s := &tennisStats{}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := &genTennisStatsReq{stats: tt.stats}
			got := s.aggregatePlayerStats(req, tt.codes)
			for pid, expect := range tt.want {
				gm, ok := got[pid]
				if !ok {
					t.Fatalf("missing player %s", pid)
				}
				for code, wantVal := range expect {
					if cast.ToString(gm[code]) == "" {
						// no-op, keep static analyzers quiet
					}
					if gm[code] != wantVal {
						t.Fatalf("player %s code %s = %v, want %v", pid, code, gm[code], wantVal)
					}
				}
			}
			
			for pid, codes := range tt.wantExist {
				gm := got[pid]
				for _, code := range codes {
					if _, ok := gm[code]; !ok {
						t.Fatalf("player %s missing code %s", pid, code)
					}
				}
			}
		})
	}
}

```