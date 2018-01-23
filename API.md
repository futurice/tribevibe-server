# API

API root at `/api/`, all routes relative to API root.

## `GET /dashboard/:group`

Where `group` is an Officevibe group. If the group parameter does not exist, returns Futu-wide data.

Returns

```json
{
  "metrics": {
    "engagement": {
      "name": "Engagement",
      "values": [
        7.8, 7.7, 6.7, 6.5, 7.5
      ]
    },
    "happiness": {
      "name": "Happiness",
      "values": [
        7.8, 7.7, 6.7, 6.5, 7.5
      ]
    }
    ...
  },
  "feedback": {
    "dateCreated": "2018-01-02",
    "question": "What kind of support would you like to receive to help you deal with stress at work?",
    "answer": "More discussions about work related stress in peer-groups, also senior coaching.",
    "tags": [
      "Constructive", "Wellness"
    ],
    "replies": [
      {
        "dateCreated": "2018-01-23",
        "message": "Thank you for your thought! This is something we should definitely improve. Are you interested to start meeting with your peers around this topic? It&#39;s true that already by sharing you feelings with others makes stress more tolerable. And one more question to you, by senior coaching do you mean more coaching for seniors or seniors to coach you?"
      }
    ]
  }
}
```

## `GET /groups`

Returns all Officevibe group names.

## `GET /feedback`

Returns

```json
{
  "feedback": [
    {
      "dateCreated": "2018-01-02",
      "question": "What kind of support would you like to receive to help you deal with stress at work?",
      "answer": "More discussions about work related stress in peer-groups, also senior coaching.",
      "tags": [
        "Constructive", "Wellness"
      ],
      "replies": [
        {
          "dateCreated": "2018-01-23",
          "message": "Thank you for your thought! This is something we should definitely improve. Are you interested to start meeting with your peers around this topic? It&#39;s true that already by sharing you feelings with others makes stress more tolerable. And one more question to you, by senior coaching do you mean more coaching for seniors or seniors to coach you?"
        }
      ]
    },
    ...
  ]
}
```
