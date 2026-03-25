## 结构体方法测试
> 演示如何测试结构体的方法，包括 mock、stub 和接口测试

### mock 框架和规则

#### mock 依赖识别规则
- **识别需要 mock 的依赖**：以下几种情况需要 mock，其余情况均不需要 mock：
    1. 外部依赖，如：数据库查询和更新、HTTP 请求、文件读写操作
    2. 第三方库
    3. 不可预测的行为，如生成随机数的函数、获取当前时间的函数等
- 使用 gomonkey.ApplyFunc、gomonkey.ApplyMethod、gomonkey.ApplyFuncSeq、gomonkey.ApplyGlobalVar 等方法对这些依赖函数进行 mock，并设置不同的返回值或行为来模拟不同的测试场景。
- 若被 mock 的函数/方法在当前提供的代码文件中没有具体实现，则不允许 mock。
- 若项目 mock/ 目录中已存在对应 interface 的 mock 实现（通常命名为 NewMockXxx），则直接使用，不重新编写。gomock 的基础用法是：
```go
mockCtrl := gomock.NewController(t)
defer mockCtrl.Finish()
mockObj := mock.NewMockInterface(mockCtrl)
mockObj.EXPECT().SomeMethod(gomock.Any()).Return(someValue)
```

#### gomonkey reflect.TypeOf 参数规则
- 指针接收者方法（`func (t *T) Foo()`）：使用 `reflect.TypeOf(&T{})`
- 值接收者方法（`func (t T) Foo()`）：使用 `reflect.TypeOf(T{})`
> 用错类型会导致 patch 无效，mock 不生效。

#### gomock ctrl 作用域规范
- **固定 mock**（所有 case 期望行为相同）：ctrl 在函数体最外层创建，`defer ctrl.Finish()` 在函数级执行
- **per-case mock**（每个 case 期望行为不同）：在 `mockSetup` 函数中创建 ctrl，`defer ctrl.Finish()` 在 `t.Run` 内执行
> 参见正确例子：TestUnit_Competition（固定 mock）vs TestUnit_tennisStats_convertTeamGamesToPlayerGames（per-case mock）

#### gomonkey patch 生命周期
- patch 应在**测试函数最外层**（循环外）初始化，`defer p.Reset()` 在函数级执行
- **不要**在 `t.Run` 内部使用 gomonkey patch：defer 不会在子测试结束时执行，会导致 mock 状态泄漏到后续 case
- 若每个 case 需要不同 mock 行为，应改用 gomock per-case 方式（见上）

> 注意：示例中的 `trpc.BackgroundContext()` 为 trpc 框架特有 API；若项目未使用 trpc，替换为标准库 `context.Background()`。

### 示例：gomonkey patch 函数 + 表驱动
```go
func TestUnitCustomIp_IsPrivateIP(t *testing.T) {
	type fields struct {
		ip string
	}
	tests := []struct {
		name       string
		fields     fields
		mockReturn bool
		want       bool
	}{
		{
			name:       "valid private IPv4",
			fields:     fields{ip: "192.168.1.1"},
			mockReturn: true,
			want:       true,
		},
		{
			name:       "valid public IPv4",
			fields:     fields{ip: "8.8.8.8"},
			mockReturn: false,
			want:       false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			var actualIP net.IP
			patches := gomonkey.ApplyFunc(IsPrivateIP, func(ip net.IP) bool {
				actualIP = ip
				return tt.mockReturn
			})
			defer patches.Reset()

			c := &CustomIp{ip: tt.fields.ip}
			got := c.IsPrivateIP()

			expectedIP := net.IP(tt.fields.ip)
			if !reflect.DeepEqual(actualIP, expectedIP) {
				t.Errorf("IsPrivateIP received IP %v, want %v", actualIP, expectedIP)
			}

			if got != tt.want {
				t.Errorf("CustomIp.IsPrivateIP() = %v, want %v", got, tt.want)
			}
		})
	}
}
```

### 示例：gomock 固定 mock + 表驱动
```go

import (
    "context"
    "testing"
    
    "git.code.oa.com/trpc-go/trpc-go"
    "git.woa.com/sport/competition/src/domain/competition"
    competitionMock "git.woa.com/sport/competition/src/domain/competition/mock"
    mockMatchEditor "git.woa.com/sport/competition/src/infra/unioneditor/mock"
    editorpb "git.woa.com/trpcprotocol/match/editor"
    "github.com/golang/mock/gomock"
)

func TestUnit_Competition(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockUeEditor := mockMatchEditor.NewMockClient(ctrl)
	mockUeEditor.EXPECT().
		UpsertCompetitionDetail(gomock.Any(), gomock.Any(), gomock.Any()).
		AnyTimes().
		Return(nil)

	mockCmpSrv := competitionMock.NewMockService(ctrl)
	mockCmpSrv.EXPECT().
		GetSeasonStage(gomock.Any(), gomock.Any(), gomock.Any()).
		AnyTimes().
		Return(&competition.SeasonStage{
			Competition: competition.Competition{
				CompetitionID: "100000",
				SeasonID:      2024,
			},
		}, nil)

	type args struct {
		ctx   context.Context
		msg   *editorpb.Competition
		diffs map[string]*editorpb.DiffData
	}

	tests := []struct {
		name    string
		args    args
		wantErr bool
	}{
		{
			name: "normal",
			args: args{
				ctx: trpc.BackgroundContext(),
				msg: &editorpb.Competition{
					CompetitionId: "100000",
				},
				diffs: nil,
			},
			wantErr: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			c := &client{
				ueCli:          mockUeEditor,
				competitionSrv: mockCmpSrv,
			}
			if err := c.Competition(tt.args.ctx, tt.args.msg, tt.args.diffs); (err != nil) != tt.wantErr {
				t.Errorf("Competition() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}

```

### 示例：gomonkey patch 方法 + 表驱动
```go

import (
	"context"
	"reflect"
	"testing"

	"git.code.oa.com/trpc-go/trpc-go"
	"git.woa.com/sport/competition/src/domain/match"
	dpbp "git.woa.com/sport/competition/src/domain/pbp"
	"github.com/agiledragon/gomonkey/v2"
	"github.com/golang/mock/gomock"
	"github.com/stretchr/testify/assert"
)

func TestUnit_IntelligenceResponse_ToPBPEntity(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	// 准备测试数据
	mockMatch := &match.Match{
		BaseInfo: match.BaseInfo{
			MID: "test-match-id",
		},
	}
	p := gomonkey.ApplyMethod(reflect.TypeOf(&IntelligenceData{}), "ToPBPEntity",
		func(i *IntelligenceData, ctx context.Context, match *match.Match) []*dpbp.PBP {
			if i.ID == 2 {
				return []*dpbp.PBP{
					{Base: dpbp.Base{Content: "test-content1"}},
					{Base: dpbp.Base{Content: "test-content2"}},
				}
			}
			return []*dpbp.PBP{{Base: dpbp.Base{Content: "test-content"}}}
		})
	defer p.Reset()
	type args struct {
		ctx   context.Context
		match *match.Match
	}
	type fields struct {
		Results []*IntelligenceData
	}
	tests := []struct {
		name   string
		fields fields
		args   args
		want   []*dpbp.PBP
	}{
		{
			name: "single_result",
			fields: fields{
				Results: []*IntelligenceData{{ID: 1}},
			},
			args: args{
				ctx:   trpc.BackgroundContext(),
				match: mockMatch,
			},
			want: []*dpbp.PBP{{Base: dpbp.Base{Content: "test-content"}}},
		},
		{
			name: "multiple_results",
			fields: fields{
				Results: []*IntelligenceData{{ID: 2}},
			},
			args: args{
				ctx:   trpc.BackgroundContext(),
				match: mockMatch,
			},
			want: []*dpbp.PBP{
				{Base: dpbp.Base{Content: "test-content1"}},
				{Base: dpbp.Base{Content: "test-content2"}},
			},
		},
		{
			name: "mixed_results",
			fields: fields{
				Results: []*IntelligenceData{{ID: 1}, {ID: 2}},
			},
			args: args{
				ctx:   trpc.BackgroundContext(),
				match: mockMatch,
			},
			want: []*dpbp.PBP{
				{Base: dpbp.Base{Content: "test-content"}},
				{Base: dpbp.Base{Content: "test-content1"}},
				{Base: dpbp.Base{Content: "test-content2"}},
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			c := &IntelligenceResponse{
				Results: tt.fields.Results,
			}
			got := c.ToPBPEntity(tt.args.ctx, tt.args.match)
			assert.Equal(t, tt.want, got)
		})
	}
}

```

### 示例：gomonkey patch 私有方法
```go

import (
	"context"
	"reflect"
	"testing"

	"git.code.oa.com/trpc-go/trpc-go"
	"git.woa.com/sport/competition/src/application/parser/nami/module"
	"git.woa.com/sport/competition/src/domain/competitor"
	"git.woa.com/sport/competition/src/domain/match"
	"git.woa.com/sport/competition/src/domain/matchstat"
	"github.com/agiledragon/gomonkey/v2"
)

func TestUnit_matchLiveParser_fillMatchLiveScore(t *testing.T) {
	// 注意：ApplyPrivateMethod 用于 patch 私有方法，需配合 -gcflags=all=-l
	p := gomonkey.ApplyPrivateMethod(reflect.TypeOf(matchLiveParser{}), "getBestOf",
		func(_ matchLiveParser, ctx context.Context, cateName string, id int64) (int64, error) {
			return 7, nil
		})
	defer p.Reset()
	type fields struct {
		fetchCli      module.FetchCli
		matchSrv      match.Service
		statSrv       matchstat.Service
		competitorSrv competitor.Service
	}
	type args struct {
		ctx      context.Context
		stats    []module.Result
		cateName string
		matchMap map[string]*match.Match
	}
	tests := []struct {
		name   string
		fields fields
		args   args
		wantMatchKey string // 期望 matchMap 中存在的 key
	}{
		{
			name: "score_above_threshold",  // scores[1]=23，高于边界值
			args: args{
				ctx: trpc.BackgroundContext(),
				stats: []module.Result{
					{
						ID: 111,
						Scores: []any{
							111,
							23,
							0,
							map[string]any{
								"ft": []int32{0, 0},
							},
						},
					},
				},
				cateName: "table_tennis",
				matchMap: map[string]*match.Match{
					"table_tennis_111": {
						BaseInfo: match.BaseInfo{
							MatchID: "1123",
						},
					},
				},
			},
			wantMatchKey: "table_tennis_111",
		},
		{
			name: "score_at_boundary",  // scores[1]=22，边界值场景
			args: args{
				ctx: trpc.BackgroundContext(),
				stats: []module.Result{
					{
						ID: 111,
						Scores: []any{
							111,
							22,
							0,
							map[string]any{
								"ft": []int32{0, 0},
							},
						},
					},
				},
				cateName: "table_tennis",
				matchMap: map[string]*match.Match{
					"table_tennis_111": {
						BaseInfo: match.BaseInfo{
							MatchID: "1123",
						},
					},
				},
			},
			wantMatchKey: "table_tennis_111",
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			m := matchLiveParser{
				fetchCli:      tt.fields.fetchCli,
				matchSrv:      tt.fields.matchSrv,
				statSrv:       tt.fields.statSrv,
				competitorSrv: tt.fields.competitorSrv,
			}
			m.fillMatchLiveScore(tt.args.ctx, tt.args.stats, tt.args.cateName, tt.args.matchMap)
			// 验证 matchMap 中的记录在处理后仍然存在（fillMatchLiveScore 不应删除记录）
			assert.NotNil(t, tt.args.matchMap[tt.wantMatchKey], "matchMap 中应保留 key: %s", tt.wantMatchKey)
		})
	}
}

```

### 示例：gomock per-case mock + mockSetup 模式
```go

func TestUnit_tennisStats_convertTeamGamesToPlayerGames(t *testing.T) {
	tests := []struct {
		name          string
		competitionID string
		seasonID      string
		teamGames     map[string]int
		mockSetup     func(ctrl *gomock.Controller) *tennisStats
		want          map[string]int
	}{
		{
			name:          "partial_teams_missing_returns_only_found_players",
			competitionID: "100001",
			seasonID:      "2024",
			teamGames: map[string]int{
				"team:t1": 3,
				"team:t2": 5,
			},
			mockSetup: func(ctrl *gomock.Controller) *tennisStats {
				mockCompetitorSrv := competitorMock.NewMockService(ctrl)
				mockCompetitorSrv.EXPECT().
					GetCompetitors(gomock.Any(), entity.SeasonStage{
						CompetitionID: "100001",
						SeasonID:      "2024",
					}, []string{"team:t1", "team:t2"}).
					Return(map[string]*dcptr.Competitor{
						"team:t1": {
							BaseInfo: dcptr.BaseInfo{
								CompetitorID: "team:t1",
							},
							TeamExtra: dcptr.TeamExtra{
								Players: []*dcptr.Competitor{
									{BaseInfo: dcptr.BaseInfo{CompetitorID: "player:p1"}},
								},
							},
						},
					}, nil).AnyTimes()
				return &tennisStats{
					competitorSrv: mockCompetitorSrv,
				}
			},
			want: map[string]int{
				"player:p1": 3,
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			ctrl := gomock.NewController(t)
			defer ctrl.Finish()

			s := tt.mockSetup(ctrl)
			ctx := trpc.BackgroundContext()

			got := s.convertTeamGamesToPlayerGames(ctx, tt.competitionID, tt.seasonID, tt.teamGames)
			assert.Equal(t, tt.want, got)
		})
	}
}
```