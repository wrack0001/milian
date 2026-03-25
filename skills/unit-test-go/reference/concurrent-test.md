## 并发测试
> 演示如何测试并发安全性，包括 goroutine、sync 包（atomic）的使用。
> 并发测试通常每个场景有独立的 goroutine 拓扑结构，不适合用表驱动统一初始化；直接用 t.Run 手动组织各场景是惯用做法。

### 示例：并发限制与错误传播测试
```go
func TestUnit_GoAndWait(t *testing.T) {
	ctx := trpc.BackgroundContext()

	t.Run("concurrency_limit", func(t *testing.T) {
		var current atomic.Int64
		var max atomic.Int64

		h := func(i int) Handler {
			return Handler{
				Name: fmt.Sprintf("h-%d", i),
				Func: func(ctx context.Context) error {
					c := current.Add(1)
					for {
						m := max.Load()
						if c <= m {
							break
						}
						if max.CompareAndSwap(m, c) {
							break
						}
					}
					time.Sleep(30 * time.Millisecond)
					current.Add(-1)
					return nil
				},
			}
		}

		var hs []Handler
		for i := 0; i < 10; i++ {
			hs = append(hs, h(i))
		}

		err := GoAndWait(ctx, 3, hs...)
		require.NoError(t, err)
		require.LessOrEqual(t, max.Load(), int64(3))
	})

	t.Run("returns_error", func(t *testing.T) {
		h1 := Handler{Name: "ok", Func: func(ctx context.Context) error { return nil }}
		h2 := Handler{Name: "bad", Func: func(ctx context.Context) error { return errors.New("boom") }}
		err := GoAndWait(ctx, 2, h1, h2)
		require.Error(t, err)
	})

	t.Run("runs_all_handlers", func(t *testing.T) {
		var cnt atomic.Int64
		var hs []Handler
		for i := 0; i < 5; i++ {
			hs = append(hs, Handler{
				Name: fmt.Sprintf("h-%d", i),
				Func: func(ctx context.Context) error {
					cnt.Add(1)
					return nil
				},
			})
		}
		err := GoAndWait(ctx, 2, hs...)
		require.NoError(t, err)
		require.Equal(t, int64(5), cnt.Load())
	})
}

```
