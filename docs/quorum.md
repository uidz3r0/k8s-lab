# etcd Quorum

etcd uses the Raft consensus algorithm.

Every write requires agreement from a majority of members.

Majority is calculated as:

```
floor(n/2) + 1
```

Examples

| Members | Majority |
|---------|----------|
|1|1|
|2|2|
|3|2|
|4|3|
|5|3|

Because of this, Kubernetes recommends:

- 3 control planes
- 5 control planes for very large clusters

Never use an even number of control planes if high availability is the goal.