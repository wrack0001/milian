## 基准测试
> 适用于性能测试和优化，使用 `BenchmarkXxx` 函数（不受 TestUnit 命名规则约束）。
> 注意：若项目使用 gomonkey，需在命令中额外添加 `-gcflags=all=-l`。

```go

// 基准测试模板示例
// 演示如何编写性能基准测试

// BenchmarkStringConcatenation 演示字符串拼接的基准测试
func BenchmarkStringConcatenation(b *testing.B) {
	// b.N 会自动调整，以获得稳定的测试结果
	for i := 0; i < b.N; i++ {
		result := ""
		for j := 0; j < 100; j++ {
			result += "a"
		}
		_ = result
	}
}

// BenchmarkStringBuilder 演示使用 strings.Builder 的基准测试
func BenchmarkStringBuilder(b *testing.B) {
	for i := 0; i < b.N; i++ {
		var builder strings.Builder
		for j := 0; j < 100; j++ {
			builder.WriteString("a")
		}
		_ = builder.String()
	}
}

// BenchmarkMapAccess 演示 map 访问的基准测试
func BenchmarkMapAccess(b *testing.B) {
	// Setup：在基准测试前准备数据
	m := make(map[int]string)
	for i := 0; i < 1000; i++ {
		m[i] = fmt.Sprintf("value_%d", i)
	}

	// 重置计时器，排除 setup 时间
	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		_ = m[i%1000]
	}
}

// BenchmarkSliceAppend 演示切片追加的基准测试
func BenchmarkSliceAppend(b *testing.B) {
	for i := 0; i < b.N; i++ {
		var slice []int
		for j := 0; j < 1000; j++ {
			slice = append(slice, j)
		}
	}
}

// BenchmarkSlicePreallocate 演示预分配切片的基准测试
func BenchmarkSlicePreallocate(b *testing.B) {
	for i := 0; i < b.N; i++ {
		slice := make([]int, 0, 1000)
		for j := 0; j < 1000; j++ {
			slice = append(slice, j)
		}
	}
}

// BenchmarkWithSubBenchmarks 演示使用子基准测试
func BenchmarkWithSubBenchmarks(b *testing.B) {
	// 测试不同大小的输入
	sizes := []int{10, 100, 1000, 10000}

	for _, size := range sizes {
		b.Run(fmt.Sprintf("size_%d", size), func(b *testing.B) {
			data := make([]int, size)
			for i := 0; i < size; i++ {
				data[i] = i
			}

			b.ResetTimer()

			for i := 0; i < b.N; i++ {
				_ = Sum(data)
			}
		})
	}
}

// BenchmarkWithMemoryAllocation 演示内存分配统计
func BenchmarkWithMemoryAllocation(b *testing.B) {
	// 报告内存分配统计
	b.ReportAllocs()

	for i := 0; i < b.N; i++ {
		// 这个操作会分配内存
		slice := make([]int, 1000)
		_ = slice
	}
}

// BenchmarkParallel 演示并行基准测试
func BenchmarkParallel(b *testing.B) {
	// 准备共享数据
	data := make([]int, 1000)
	for i := 0; i < 1000; i++ {
		data[i] = i
	}

	b.ResetTimer()

	// RunParallel 会并行运行基准测试
	b.RunParallel(func(pb *testing.PB) {
		for pb.Next() {
			_ = Sum(data)
		}
	})
}

// BenchmarkWithSetup 演示带 setup 和 teardown 的基准测试
func BenchmarkWithSetup(b *testing.B) {
	// Setup：每次基准测试前执行
	cache := NewCache()
	for i := 0; i < 100; i++ {
		cache.Set(fmt.Sprintf("key_%d", i), i)
	}

	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		key := fmt.Sprintf("key_%d", i%100)
		_, _ = cache.Get(key)
	}

	b.StopTimer()
	// Teardown：清理资源
	cache.Clear()
}

// BenchmarkCompareAlgorithms 演示比较不同算法的性能
func BenchmarkCompareAlgorithms(b *testing.B) {
	data := []int{5, 2, 8, 1, 9, 3, 7, 4, 6}

	b.Run("BubbleSort", func(b *testing.B) {
		for i := 0; i < b.N; i++ {
			b.StopTimer()
			testData := make([]int, len(data))
			copy(testData, data)
			b.StartTimer()

			BubbleSort(testData)
		}
	})

	b.Run("QuickSort", func(b *testing.B) {
		for i := 0; i < b.N; i++ {
			b.StopTimer()
			testData := make([]int, len(data))
			copy(testData, data)
			b.StartTimer()

			QuickSort(testData)
		}
	})
}

// BenchmarkWithDifferentInputs 演示测试不同输入的性能
func BenchmarkWithDifferentInputs(b *testing.B) {
	inputs := []struct {
		name string
		data []int
	}{
		{
			name: "已排序",
			data: []int{1, 2, 3, 4, 5, 6, 7, 8, 9, 10},
		},
		{
			name: "逆序",
			data: []int{10, 9, 8, 7, 6, 5, 4, 3, 2, 1},
		},
		{
			name: "随机",
			data: []int{5, 2, 8, 1, 9, 3, 7, 4, 6, 10},
		},
	}

	for _, input := range inputs {
		b.Run(input.name, func(b *testing.B) {
			for i := 0; i < b.N; i++ {
				b.StopTimer()
				testData := make([]int, len(input.data))
				copy(testData, input.data)
				b.StartTimer()

				BubbleSort(testData)
			}
		})
	}
}

// BenchmarkCPUIntensive 演示 CPU 密集型操作的基准测试
func BenchmarkCPUIntensive(b *testing.B) {
	b.ReportAllocs()

	for i := 0; i < b.N; i++ {
		_ = Fibonacci(20)
	}
}

// 以上基准测试假设 Sum/BubbleSort/QuickSort/Fibonacci/Cache 已在同包中定义

```

### 基准测试运行命令

1. 运行所有基准测试：
   go test -ldflags "-X google.golang.org/protobuf/reflect/protoregistry.conflictPolicy=warn" -bench=.

2. 运行特定基准测试：
   go test -ldflags "-X google.golang.org/protobuf/reflect/protoregistry.conflictPolicy=warn" -bench=BenchmarkStringConcatenation

3. 运行基准测试并显示内存分配：
   go test -ldflags "-X google.golang.org/protobuf/reflect/protoregistry.conflictPolicy=warn" -bench=. -benchmem

4. 运行基准测试指定时间：
   go test -ldflags "-X google.golang.org/protobuf/reflect/protoregistry.conflictPolicy=warn" -bench=. -benchtime=10s

5. 运行基准测试指定次数：
   go test -ldflags "-X google.golang.org/protobuf/reflect/protoregistry.conflictPolicy=warn" -bench=. -benchtime=100x

6. 比较基准测试结果：
   go test -ldflags "-X google.golang.org/protobuf/reflect/protoregistry.conflictPolicy=warn" -bench=. > old.txt
   # 修改代码后
   go test -ldflags "-X google.golang.org/protobuf/reflect/protoregistry.conflictPolicy=warn" -bench=. > new.txt
   benchcmp old.txt new.txt

7. 生成 CPU profile：
   go test -ldflags "-X google.golang.org/protobuf/reflect/protoregistry.conflictPolicy=warn" -bench=. -cpuprofile=cpu.prof

8. 生成内存 profile：
   go test -ldflags "-X google.golang.org/protobuf/reflect/protoregistry.conflictPolicy=warn" -bench=. -memprofile=mem.prof

### 基准测试结果解读

BenchmarkStringConcatenation-8    100000    12345 ns/op    1024 B/op    10 allocs/op
                           |      |         |              |            |
                           |      |         |              |            每次操作的内存分配次数
                           |      |         |              每次操作分配的字节数
                           |      |         每次操作的纳秒数
                           |      运行次数
                           GOMAXPROCS 值

### 性能优化建议

1. 使用 b.ResetTimer() 排除 setup 时间
2. 使用 b.StopTimer() 和 b.StartTimer() 排除不需要测量的代码
3. 使用 b.ReportAllocs() 报告内存分配
4. 使用子基准测试测试不同场景
5. 使用 b.RunParallel() 测试并发性能
6. 避免在循环内部进行不必要的内存分配
7. 使用 -benchmem 标志查看内存使用情况
8. 多次运行基准测试以获得稳定结果

