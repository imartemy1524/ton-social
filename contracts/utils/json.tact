const JSON_TYPE_OBJECT: Int = 0;
const JSON_TYPE_ARRAY: Int = 1;
const JSON_TYPE_STRING: Int = 2;
const JSON_TYPE_NUMBER: Int = 3;
const JSON_TYPE_COINS: Int = 4;

struct ObjectElement{
    data: String;
}

struct JsonBuilderObject{
    //slice - String
    content: map<Int as uint8, ObjectElement>;
    elementsCount: Int as uint64 = 0;
}
struct JsonBuilderArray{
    //slice - String
    content: map<Int as uint8, ObjectElement>;
    elementsCount: Int as uint64 = 0;
}

struct JsonBuilderString{
    value: String;
}
struct JsonBuilderNumber{
    value: Int as uint64;
}
struct JsonBuilderCoins{
    value: Int as coins;
}

fun createJsonArray(): JsonBuilderArray{
    //TODO: toCell costs a lot of gas
    return JsonBuilderArray{content: emptyMap()};
}
fun createJsonObject(): JsonBuilderObject{
    return JsonBuilderObject{content: emptyMap()};
}

inline extends fun toString(self: JsonBuilderObject): String {
    let builder: StringBuilder = beginString();
    builder.append("{");
    foreach(key, value in self.content){
        builder.append(value.data);
        if(key != self.elementsCount - 1){
            builder.append(",");
        }
    }
    builder.append("}");
    return builder.toString();
}
inline extends fun toString(self: JsonBuilderArray): String {
    let builder: StringBuilder = beginString();
    builder.append("[");
    foreach(key, value in self.content){
        builder.append(value.data);
        if(key != self.elementsCount-1){
            builder.append(",");
        }
    }
    builder.append("]");
    return builder.toString();
}


inline fun jsonValue(key: String, value: String): ObjectElement{
    return ObjectElement{data: beginString().concat("\"").concat(key).concat("\":").concat(value).toString()};
}

extends fun appendCoins(self: JsonBuilderObject, key: String, value: Int): JsonBuilderObject {
    self.content.set(self.elementsCount, jsonValue(key, value.toCoinsString()));
    self.elementsCount += 1;
    return self;
}
extends fun appendNumber(self: JsonBuilderObject, key: String, value: Int): JsonBuilderObject {
    self.content.set(self.elementsCount, jsonValue(key, value.toString()));
    self.elementsCount += 1;
    return self;
}
extends fun appendString(self: JsonBuilderObject, key: String, value: String): JsonBuilderObject {
    self.content.set(self.elementsCount, jsonValue(key, beginString().concat("\"").concat(value).concat("\"").toString()));
    self.elementsCount += 1;
    return self;
}
extends fun appendObject(self: JsonBuilderObject, key: String, value: JsonBuilderObject): JsonBuilderObject {
    self.content.set(self.elementsCount, jsonValue(key, value.toString()));
    self.elementsCount += 1;
    return self;
}
extends fun appendArray(self: JsonBuilderObject, key: String, value: JsonBuilderArray): JsonBuilderObject {
    self.content.set(self.elementsCount, jsonValue(key, value.toString()));
    self.elementsCount += 1;
    return self;
}
extends fun appendNull(self: JsonBuilderObject, key: String): JsonBuilderObject {
    self.content.set(self.elementsCount, jsonValue(key, "null"));
    self.elementsCount += 1;
    return self;
}
extends fun appendBool(self: JsonBuilderObject, key: String, value: Bool): JsonBuilderObject {
    self.content.set(self.elementsCount, jsonValue(key, value? "true" : "false"));
    self.elementsCount += 1;
    return self;
}

extends fun appendCoins(self: JsonBuilderArray, value: Int): JsonBuilderArray {
    self.content.set(self.elementsCount, ObjectElement{data: value.toCoinsString()});
    self.elementsCount += 1;
    return self;
}
extends fun appendNumber(self: JsonBuilderArray, value: Int): JsonBuilderArray {
    self.content.set(self.elementsCount, ObjectElement{data: value.toString()});
    self.elementsCount += 1;
    return self;
}
extends fun appendString(self: JsonBuilderArray, value: String): JsonBuilderArray {
    self.content.set(self.elementsCount, ObjectElement{data: beginString().concat("\"").concat(value).concat("\"").toString()});
    self.elementsCount += 1;
    return self;
}
extends fun appendObject(self: JsonBuilderArray, value: JsonBuilderObject): JsonBuilderArray {
    self.content.set(self.elementsCount, ObjectElement{data: value.toString()});
    self.elementsCount += 1;
    return self;
}
extends fun appendArray(self: JsonBuilderArray, value: JsonBuilderArray): JsonBuilderArray {
    self.content.set(self.elementsCount, ObjectElement{data: value.toString()});
    self.elementsCount += 1;
    return self;
}
extends fun appendNull(self: JsonBuilderArray): JsonBuilderArray {
    self.content.set(self.elementsCount, ObjectElement{data: "null"});
    self.elementsCount += 1;
    return self;
}
extends fun appendBool(self: JsonBuilderArray, value: Bool): JsonBuilderArray {
    self.content.set(self.elementsCount, ObjectElement{data: value? "true" : "false"});
    self.elementsCount += 1;
    return self;
}