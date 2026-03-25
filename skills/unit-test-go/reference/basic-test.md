# 按 `Arrange-Act-Assert` 组织测试结构，优先用**表驱动** + `t.Run` 罗列多组用例覆盖正常路径与关键边界（如：空输入、特殊字符、nil/空切片、不同类型/组合输入等）；断言要同时包含 **got / want**（必要时带格式化提示），确保失败时可快速定位问题

## 正确例子
```go
func TestUnit_Add(t *testing.T) {
    // Arrange
    a, b := 2, 3
    expected := 5
    
    // Act
    result := Add(a, b)
	
	// Assert
	assert.Equalf(t, expected, result,"Add(%d, %d) = %d, 期望 %d", a, b, result, expected)
}
```

### 正确例子
```go

func TestUnitCleanString(t *testing.T) {
	type args struct {
		input string
	}
	tests := []struct {
		name string
		args args
		want string
	}{
		{
			name: "test",
			args: args{
				input: "A&B C",
			},
			want: "A、BC",
		},
		{
			name: "test",
			args: args{
				input: "Hello! 你好&世界",
			},
			want: "Hello你好、世界",
		},
		{
			name: "test",
			args: args{
				input: "123_@#&",
			},
			want: "123、",
		},
		{
			name: "test",
			args: args{
				input: "123_@#&/-",
			},
			want: "123、/-",
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := CleanString(tt.args.input); got != tt.want {
				t.Errorf("CleanString() = %v, want %v", got, tt.want)
			}
		})
	}
}

```

### 泛型UT代码 - 正确例子
```go

func TestUnit_Sum(t *testing.T) {
	tests := []struct {
		name string
		in   []any
		want float64
	}{
		{
			name: "empty",
			in:   nil,
			want: 0,
		},
		{
			name: "ints",
			in:   []any{1, 2, 3},
			want: 6,
		},
		{
			name: "floats",
			in:   []any{1.5, 2.25},
			want: 3.75,
		},
		{
			name: "numeric_strings",
			in:   []any{"1", "2", "3"},
			want: 6,
		},
		{
			name: "mix_number_and_string",
			in:   []any{1, "2"},
			want: 3,
		},
		{
			name: "zeros",
			in:   []any{0, 0, 0},
			want: 0,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := Sum(tt.in...)
			if got != tt.want {
				t.Fatalf("Sum() got=%v want=%v", got, tt.want)
			}
		})
	}
}

// Sum 多数据加和
func Sum[T comparable](values ...T) float64 {
    if len(values) == 0 {
        return 0
    }
    var sum float64
    for _, v := range values {
        sum += cast.ToFloat64(v)
    }
    return sum
}

```
