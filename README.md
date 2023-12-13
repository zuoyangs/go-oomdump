# go-oomdump

## 堆内oom场景
1. 大量的对象创建，导致堆内存耗尽。
   这通常发生在程序中创建大量对象，且这些对象长时间存在，不会被垃圾回收器回收的情况下。
        import java.util.ArrayList;
        import java.util.List;

        public class OOMExample {
            public static void main(String[] args) {
                List<Object> list = new ArrayList<>();
                while (true) {
                    list.add(new Object());
                }
            }
        }

2. 大对象分配导致堆内存耗尽。
   当程序尝试分配一个非常大的对象，而堆内存中没有足够的连续空间来容纳该对象时，也会发生OOM。
        public class OOMExample {
            public static void main(String[] args) {
                int[] array = new int[Integer.MAX_VALUE];
            }
        }

3. 内存泄漏导致堆内存耗尽。
    当程序创建的对象，在程序结束时没有被垃圾回收器回收，就会发生内存泄漏。
    常见的内存泄漏场景包括：长生命周期的对象持有短生命周期对象的引用、静态集合类、单例模式等。
        import java.util.HashMap;
        import java.util.Map;

        public class OOMExample {
            static Map<String, Object> cache = new HashMap<>();

            public static void main(String[] args) {
                while (true) {
                    cache.put(new String(), new byte[1024 * 1024 * 10]); // 每次分配10MB内存并缓存起来
                }
            }
        }

4. 死循环和死锁。
    死循环和死锁是两个常见的内存泄漏场景。
    死循环和死锁本身不直接导致OOM，但如果它们导致程序无法继续执行或释放资源，间接地可能导致OOM。
    例如，一个死循环不断地创建新对象而不释放它们，最终可能耗尽堆内存。同样地，死锁可能导致程序无法执行关键部分的代码，从而无法释放资源。请注意，这些情况下的OOM通常与其他问题相关，如代码逻辑错误或并发控制不当。

5. 线程本地存储（Thread Local Storage, TLS）
    线程本地存储用于存储线程特有的数据。如果线程数量过多，且每个线程都存储了大量数据，可能导致堆内存耗尽。

        import java.lang.reflect.Field;

        public class OOMExample {
            public static void main(String[] args) throws Exception {
                Thread[] threads = new Thread[Integer.MAX_VALUE];
                for (int i = 0; i < threads.length; i++) {
                    threads[i] = new Thread(() -> {
                        // 消耗本地线程存储空间
                        byte[] data = new byte[1024 * 1024 * 10]; // 分配10MB内存空间
                        Field field = Thread.class.getDeclaredField("threadLocals");
                        field.setAccessible(true);
                        field.set(Thread.currentThread(), data); // 将大对象存入本地线程存储中
                    });
                    threads[i].start();
                }
            }
        }


## 堆外oom场景
1. 直接缓冲区内存泄漏。
    在Java中，使用NIO（New I/O）包进行网络通信或文件读写时，可以通过分配直接缓冲区（Direct Buffer）来提高性能。这些直接缓冲区是在JVM堆外分配的内存，如果不正确地管理，可能导致内存泄漏，最终引发OOM。
        import java.nio.ByteBuffer;
        import java.util.ArrayList;
        import java.util.List;

        public class OOMExample {
            public static void main(String[] args) {
                List<ByteBuffer> list = new ArrayList<>();
                while (true) {
                    ByteBuffer buffer = ByteBuffer.allocateDirect(1024 * 1024 * 10); // 每次分配10MB的直接缓冲区
                    list.add(buffer); // 将缓冲区添加到列表中，防止被垃圾回收
                }
            }
        }

2. 使用第三方库或JNI（Java Native Interface）
    第三方库或JNI可能会导致内存泄漏。例如，使用第三方库或JNI可能会导致内存泄漏，如使用JNI来调用C/C++代码，或者使用JNI来调用Java代码。
    请注意，如果使用第三方库或JNI，请确保它们的使用方式正确，并在使用完毕后及时释放资源。


3. 线程栈空间溢出（Stack Overflow Error）
    Stack Overflow Error通常被视为错误而非异常，但在极端情况下，如果线程所需的栈空间超过JVM允许的最大值，也可能导致OOM。这通常发生在递归调用过深或线程所需的局部变量过多时。例如：

        public class OOMExample {
            public static void main(String[] args) {
                recurse();
            }

            public static void recurse() {
                byte[] data = new byte[1024 * 1024]; // 在栈上分配1MB的空间
                recurse(); // 递归调用自己，不断消耗栈空间
            }
        }

4. 映射文件过大
    映射文件是一种特殊的文件，它包含了内存映射的内存块。如果映射文件过大，可能会导致OOM。
    使用 MappedByteBuffer 可以将文件映射到内存中，提高文件读写的性能。但是，如果映射的文件过大，可能导致堆外内存溢出。例如：
        import java.io.RandomAccessFile;
        import java.nio.MappedByteBuffer;
        import java.nio.channels.FileChannel;
        import java.nio.file.Path;
        import java.nio.file.Paths;
        import java.util.ArrayList;
        import java.util.List;

        public class OOMExample {
            public static void main(String[] args) throws Exception {
                Path filePath = Paths.get("large_file"); // 指定一个非常大的文件
                RandomAccessFile file = new RandomAccessFile(filePath.toFile(), "rw");
                FileChannel channel = file.getChannel();
                List<MappedByteBuffer> list = new ArrayList<>();
                while (true) {
                    MappedByteBuffer buffer = channel.map(FileChannel.MapMode.READ_WRITE, 0, 1024 * 1024 * 100); // 每次映射100MB的文件到内存中
                    list.add(buffer); // 将映射的缓冲区添加到列表中，防止被垃圾回收
                }
            }
        }

## Metaspace OOM场景
1. 加载大量的类或频繁生成动态代理
    应用程序需要加载大量的类（例如，使用了很多框架、库或动态生成的类），或者频繁地生成动态代理类，Metaspace的使用量可能会迅速增加，导致OOM。
        import java.lang.reflect.Proxy;
        import java.lang.reflect.InvocationHandler;
        import java.lang.reflect.Method;

        public class MetaspaceOOMExample {
            public static void main(String[] args) {
                while (true) {
                    Enhancer enhancer = new Enhancer();
                    enhancer.setSuperclass(Object.class);
                    enhancer.setUseCache(false); // 防止缓存导致的类加载过多
                    enhancer.setCallback((InvocationHandler) (proxy, method, args1) -> null);
                    enhancer.create(); // 每次创建不同的代理类，消耗Metaspace
                }
            }
        }

2. 应用程序类加载器泄漏
    应用程序的类加载器（例如，自定义的类加载器）泄漏，它们所加载的类的元数据也将不会被垃圾回收，从而导致Metaspace OOM。
        import java.lang.reflect.Method;

        public class LeakyClassLoader extends ClassLoader {
            @Override
            public Class<?> loadClass(String name) throws ClassNotFoundException {
                if (name.startsWith("com.example.")) {
                    return findClass(name); // 仅加载特定包下的类
                }
                return super.loadClass(name);
            }
        }

        public class MetaspaceOOMExample {
            static List<LeakyClassLoader> loaders = new ArrayList<>();
            public static void main(String[] args) throws Exception {
                while (true) {
                    LeakyClassLoader loader = new LeakyClassLoader();
                    loader.loadClass("com.example.SomeClass"); // 加载一个类
                    loaders.add(loader); // 将类加载器存储起来，防止被垃圾回收
                }
            }
        }

3. 不当使用java代理和反射
    不当使用Java代理（如Proxy类）和反射API可能导致生成大量的动态类，进而消耗Metaspace。
        import java.lang.reflect.InvocationHandler;
        import java.lang.reflect.Method;
        import java.lang.reflect.Proxy;
        import java.util.stream.IntStream;

        public class MetaspaceOOMExample {
            public static void main(String[] args) {
                IntStream.range(0, Integer.MAX_VALUE).forEach(i -> {
                    Enhancer enhancer = new Enhancer();
                    enhancer.setSuperclass(Object.class);
                    enhancer.setUseCache(false); // 防止缓存导致的类加载过多
                    enhancer.setCallback((InvocationHandler) (proxy, method, args1) -> null);
                    enhancer.create(); // 创建大量的代理类，消耗Metaspace
                });
            }
        }
4. 递归创建对象
5. 持有大量的类加载器引用
6. 加载一个过大的类
7. 加载一个过大的Jar包
8. 加载一个过大的XML文件
9.  加载一个过大的ProtoBuf文件
10. 加载一个过大的Thrift文件
11. 加载一个过大的Avro文件
## 解决方案
1. 检查代码，是否存在加载大量类的情况，如：动态代理、反射、RPC框架等。
2. 减少加载的类数量，如：使用类加载器隔离，避免加载过多的类。
3. 减少加载的Jar包数量，如：使用类加载器隔离，避免加载过多的Jar包。
4. 减少加载的XML文件数量，如：使用类加载器隔离，避免加载过多的XML文件。
5. 检查是否存在内存泄漏，如：内存泄漏导致频繁GC，JVM内存不足。
6. 检查是否存在内存泄漏，如：内存泄漏导致频繁GC，JVM内存不足。
7. 减少加载的ProtoBuf文件数量，如：使用类加载器隔离，避免加载过多的ProtoBuf文件。
8. 减少加载的Thrift文件数量，如：使用类加载器隔离，避免加载过多的Thrift文件。
9. 减少加载的Avro文件数量，如：使用类加载器隔离，避免加载过多的Avro文件。