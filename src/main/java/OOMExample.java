// 模拟 README.md 中堆内 oom 场景
// 大量的对象创建，导致堆内存耗尽。
// 通常发生在程序中创建大量对象，且这些对象长时间存在，不会被垃圾回收器回收的情况下。

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
