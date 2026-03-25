## 结构体方法测试模板示例
> 演示如何测试结构体的方法，包括 mock、stub 和接口测试

## mock 框架和规则
### 判断是否有对象或者函数或方法需要mock，并使用gomonkey进行mock
- **识别需要mock的依赖**:
  以下几种情况需要mock，其余情况均不需要mock:
    1. 外部依赖，如：数据库查询和更新、HTTP请求、文件读写操作。
    2. 第三方库
    3. 不可预测的行为，如生成随机数的函数，获取当前时间的函数等
- 使用gomonkey.ApplyFunc、gomonkey.ApplyMethod、gomonkey.ApplyFuncSeq、gomonkey.ApplyGlobalVar等方法对这些依赖函数进行mock，并设置不同的返回值或行为来模拟不同的测试场景。
- 当所需mock的函数/结构体在给出的上下文中不存在具体定义时，**不允许mock**。
- mock之前首先检查提供的依赖中是否提供了对应interface的mock方法，一般对应的mock方法是NewMockSomeInterface，如果已经提供，那么使用gomock进行mock，不要新编写对应的mock方法。gomock的基础用法是：
```go
mockCtrl := gomock.NewController(t)
defer mockCtrl.Finish()
mockObj := mock.NewMockInterface(mockCtrl)
mockObj.EXPECT().SomeMethod(gomock.Any()).Return(someValue)
```

### 正确例子
```go
func TestCustomIp_IsPrivateIP(t *testing.T) {
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

### 正确例子
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

### 正确例子
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
			name: "normal",
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
			name: "normal",
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
			name: "normal",
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
			assert.Equal(t, got, tt.want)
		})
	}
}

```

### 正确例子
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
	}{
		{
			name: "normal",
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
		},
		{
			name: "normal2",
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
		})
	}
}

```

### 正确例子
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
			name:          "competitor_not_found",
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