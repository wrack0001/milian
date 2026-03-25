## 错误处理与断言规范

### 【必须】错误必须被处理

在测试中，所有返回的错误都必须被检查和处理，不能忽略。

```go
// ❌ 错误：忽略错误
func TestUnit_CreateUser(t *testing.T) {
    user := &User{Name: "张三"}
    service.CreateUser(user) // 忽略了错误
}

// ✅ 正确：检查错误
func TestUnit_CreateUser(t *testing.T) {
    user := &User{Name: "张三"}
    err := service.CreateUser(user)
    if err != nil {
        t.Errorf("期望没有错误，但得到: %v", err)
    }
}
```

### 【推荐】使用 errors.Is 和 errors.As

Go 1.13+ 推荐使用 `errors.Is` 和 `errors.As` 进行错误判断。

```go
// 使用 errors.Is 检查错误类型
func TestUnit_GetUser(t *testing.T) {
    _, err := service.GetUser(999)
    
    if !errors.Is(err, ErrUserNotFound) {
        t.Errorf("期望 ErrUserNotFound，但得到: %v", err)
    }
}

// 使用 errors.As 提取错误信息
func TestUnit_ValidateInput(t *testing.T) {
    err := ValidateInput("invalid")
    
    var validationErr *ValidationError
    if !errors.As(err, &validationErr) {
        t.Error("期望 ValidationError 类型的错误")
    }
    
    if validationErr.Field != "input" {
        t.Errorf("期望字段为 'input'，但得到 '%s'", validationErr.Field)
    }
}
```

### 【推荐】区分 Fatal 和 Error

- 使用 `t.Fatal` / `t.Fatalf`：当错误发生后无法继续测试时
- 使用 `t.Error` / `t.Errorf`：当错误发生后仍可继续验证其他条件时

```go
func TestUnit_ProcessData(t *testing.T) {
    data, err := LoadData()
    if err != nil {
        // 无法加载数据，后续测试无法进行
        t.Fatalf("加载数据失败: %v", err)
    }
    
    result := ProcessData(data)
    
    // 验证多个条件
    if result.Count != 10 {
        t.Errorf("期望 Count 为 10，但得到 %d", result.Count)
    }
    
    if result.Sum != 100 {
        t.Errorf("期望 Sum 为 100，但得到 %d", result.Sum)
    }
}
```

### 【推荐】测试错误场景

每个可能返回错误的函数都应该测试错误场景。

```go
func TestUnit_Divide(t *testing.T) {
    t.Run("正常除法", func(t *testing.T) {
        result, err := Divide(10, 2)
        if err != nil {
            t.Fatalf("期望没有错误，但得到: %v", err)
        }
        if result != 5 {
            t.Errorf("期望 5，但得到 %d", result)
        }
    })
    
    t.Run("除零错误", func(t *testing.T) {
        _, err := Divide(10, 0)
        if err == nil {
            t.Error("期望返回错误，但没有错误")
        }
        if !errors.Is(err, ErrDivideByZero) {
            t.Errorf("期望 ErrDivideByZero，但得到: %v", err)
        }
    })
}
```

### 断言最佳实践

### 【推荐】基础断言模式

使用清晰的断言模式，提供有用的错误信息。

```go
// 断言相等
func TestUnit_Add(t *testing.T) {
    result := Add(2, 3)
    expected := 5
	assert.Equal(t, expected, result, "Add(2, 3) = %d, 期望 %d", result, expected)
}

// 断言不相等
func TestUnit_GenerateID(t *testing.T) {
    id1 := GenerateID()
    id2 := GenerateID()
	assert.NotEqual(t, id1, id2, "期望生成不同的 ID，但得到相同的 ID")
}

// 断言为 nil
func TestUnit_FindUser(t *testing.T) {
    user, err := FindUser(999)
    assert.Error(t, err, "期望用户不存在时返回错误")
	assert.Nil(t, user, "期望返回 nil，但得到: %v", user)
}

// 断言不为 nil
func TestUnit_CreateUser(t *testing.T) {
    user := CreateUser("张三")
	assert.NotNil(t, user, "期望返回用户对象，但得到 nil")
}
```

### 【必须】使用 testify/assert 库
对于复杂项目，可以使用 `github.com/stretchr/testify/assert` 库简化断言。

```go
import (
    "testing"
    "github.com/stretchr/testify/assert"
)

func TestUnit_CreateUser(t *testing.T) {
    user, err := CreateUser("张三", 25)
    
    // 断言没有错误
    assert.NoError(t, err)
    
    // 断言不为 nil
    assert.NotNil(t, user)
    
    // 断言相等
    assert.Equal(t, "张三", user.Name)
    assert.Equal(t, 25, user.Age)
    
    // 断言包含
    assert.Contains(t, user.Name, "张")
    
    // 断言长度
    assert.Len(t, user.Tags, 3)
}

func TestUnit_GetUser(t *testing.T) {
    user, err := GetUser(999)
    
    // 断言有错误
    assert.Error(t, err)
    
    // 断言错误类型
    assert.ErrorIs(t, err, ErrUserNotFound)
    
    // 断言为 nil
    assert.Nil(t, user)
}
```

### 【推荐】断言复杂对象

测试复杂对象时，可以使用 `github.com/stretchr/testify/assert` 库提供的 `EqualValues` 和 `assert.Equalf` 方法。

```go
func TestUnit_CreateOrder(t *testing.T) {
    order, err := CreateOrder(&OrderRequest{
        UserID:  1,
        Items:   []string{"item1", "item2"},
        Total:   100.0,
    })
    
    if err != nil {
        t.Fatalf("期望没有错误，但得到: %v", err)
    }
	
	assert.NotNilf(t, order, "期望返回订单对象，但得到 nil")
	
	result := &Order{
		ID:      1,
		UserID:  1,
		Items:   []string{"item1", "item2"},
		Total:   100.0,
		Status:  "pending",
    }
	assert.Equalf(t, result, order, "与期望返回订单对象不一致")
}
```

### 错误信息格式

### 【推荐】提供清晰的错误信息

错误信息应该清晰地说明期望值和实际值。

```go
// ❌ 不好：信息不清晰
if result != expected {
    t.Error("测试失败")
}

// ✅ 好：提供详细信息
if result != expected {
    t.Errorf("Add(2, 3) = %d, 期望 %d", result, expected)
}

// ✅ 更好：提供上下文信息
if result != expected {
    t.Errorf("测试 Add 函数失败: 输入 (2, 3), 得到 %d, 期望 %d", result, expected)
}
```

### 【推荐】使用格式化字符串

使用 `%v`、`%d`、`%s` 等格式化占位符。

```go
// 整数
t.Errorf("期望 %d，但得到 %d", expected, actual)

// 字符串
t.Errorf("期望 %q，但得到 %q", expected, actual)

// 通用值
t.Errorf("期望 %v，但得到 %v", expected, actual)

// 类型
t.Errorf("期望类型 %T，但得到 %T", expected, actual)

// 带详细信息的值
t.Errorf("期望 %#v，但得到 %#v", expected, actual)
```

### 表驱动测试中的错误处理

### 【推荐】在表驱动测试中处理错误

```go
func TestUnit_Validate(t *testing.T) {
    tests := []struct {
        name      string
        input     string
        wantErr   bool
        errType   error
    }{
        {
            name:    "有效输入",
            input:   "valid",
            wantErr: false,
        },
        {
            name:    "空输入",
            input:   "",
            wantErr: true,
            errType: ErrEmptyInput,
        },
        {
            name:    "无效格式",
            input:   "invalid@",
            wantErr: true,
            errType: ErrInvalidFormat,
        },
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            err := Validate(tt.input)
            
            // 检查是否应该有错误
            if (err != nil) != tt.wantErr {
                t.Errorf("Validate() error = %v, wantErr %v", err, tt.wantErr)
                return
            }
            
            // 如果期望错误，检查错误类型
            if tt.wantErr && !errors.Is(err, tt.errType) {
                t.Errorf("期望错误类型 %v，但得到 %v", tt.errType, err)
            }
        })
    }
}
```

### 常见错误处理场景

### 场景 1：文件操作错误

```go
func TestUnit_ReadFile(t *testing.T) {
    t.Run("文件存在", func(t *testing.T) {
        content, err := ReadFile("testdata/test.txt")
        if err != nil {
            t.Fatalf("读取文件失败: %v", err)
        }
        if len(content) == 0 {
            t.Error("期望文件内容不为空")
        }
    })
    
    t.Run("文件不存在", func(t *testing.T) {
        _, err := ReadFile("nonexistent.txt")
        if err == nil {
            t.Error("期望返回错误，但没有错误")
        }
        if !os.IsNotExist(err) {
            t.Errorf("期望文件不存在错误，但得到: %v", err)
        }
    })
}
```

### 场景 2：网络请求错误

```go
func TestUnit_FetchData(t *testing.T) {
    t.Run("请求成功", func(t *testing.T) {
        data, err := FetchData("http://example.com/api")
        if err != nil {
            t.Fatalf("请求失败: %v", err)
        }
        if data == nil {
            t.Error("期望返回数据，但得到 nil")
        }
    })
    
    t.Run("网络超时", func(t *testing.T) {
        ctx, cancel := context.WithTimeout(trpc.BackgroundContext(), 1*time.Millisecond)
        defer cancel()
        
        _, err := FetchDataWithContext(ctx, "http://example.com/api")
        if err == nil {
            t.Error("期望返回超时错误，但没有错误")
        }
        if !errors.Is(err, context.DeadlineExceeded) {
            t.Errorf("期望超时错误，但得到: %v", err)
        }
    })
}
```

### 场景 3：数据库操作错误

```go
func TestUnit_SaveUser(t *testing.T) {
    t.Run("保存成功", func(t *testing.T) {
        user := &User{Name: "张三", Age: 25}
        err := db.SaveUser(user)
        if err != nil {
            t.Fatalf("保存用户失败: %v", err)
        }
		assert.NotZerof(t, user.ID, "期望用户 ID 不为 0")
    })
    
    t.Run("唯一约束冲突", func(t *testing.T) {
        user := &User{Name: "张三", Age: 25}
        require.NoError(t, db.SaveUser(user), "前置保存失败")
        
        // 尝试保存重复用户
        err := db.SaveUser(user)
        if err == nil {
            t.Error("期望返回唯一约束错误，但没有错误")
        }
        
        var dbErr *DatabaseError
        if !errors.As(err, &dbErr) {
            t.Errorf("期望 DatabaseError 类型，但得到: %T", err)
        }
        if dbErr.Code != "UNIQUE_VIOLATION" {
            t.Errorf("期望错误码 'UNIQUE_VIOLATION'，但得到 '%s'", dbErr.Code)
        }
    })
}
```

