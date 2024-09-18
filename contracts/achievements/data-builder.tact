inline extends fun countFromType(self: IndividualContentAchivement): String{
    let ans = beginString().concat("1");
    repeat((self.type % 0x10)-1){
        ans.append("0");
    }
    return ans.toString();
}

inline extends fun buildNftName(self: IndividualContentAchivement, index: Int): String{
    let ans = beginString().concat("🏆 Achievement: ").concat(self.countFromType());
    let amount = self.type % 0x10;
    ans.append(" ");
    ans.append(self.activityType(amount));
    return ans.toString();
}

inline extends fun buildDescription(self: IndividualContentAchivement, index: Int): String{
    let ans = beginString()
        .concat("This unique SBT-achievement #").concat(index.toString())
        .concat(" was granted to user ").concat(self.owner.toString())
        .concat(" for activity in NetoTon: ").concat(self.activityType(self.type % 0x10));
    return ans.toString();
}
inline extends fun buildAttributesString(self: IndividualContentAchivement): String {
    let builderAttributes = createJsonArray()
    .appendObject(
        createJsonObject()
            .appendString("trait_type", "Activity type")
            .appendString("value", buildAchievementTypeForSvg(self.type))
    )
    .appendObject(
        createJsonObject()
            .appendString("trait_type", "Amount")
            .appendString("value", self.countFromType())
    );
    return builderAttributes.toString();
}


inline extends fun activityType(self: IndividualContentAchivement, amount: Int): String{
    if(self.type <= 0x10){
        return (amount == 1 ? "post written" : "posts written");
    }
    else if(self.type <= 0x20){
        return(amount == 1 ? "like given" : "likes given");
    }
    else if(self.type <= 0x30){
        return(amount == 1 ? "comment written" : "comments written");
    }
    else if(self.type <= 0x40){
        return(amount == 1 ? "subscribtion gived" : "subscribtions gived");
    }
    return "";
}



inline fun buildCountersTextForSvg(value: Int): String{
    if(value == 1){
        return "⠀1⠀";
    }
    if(value == 2){
        return "10";
    }
    if(value == 3){
        return "100";
    }
    if(value == 4){
        return "1K";
    }
    if(value == 5){
        return "10K";
    }
    if(value == 6){
        return "<tspan dy=\"-18px\" dx=\"4px\">100</tspan><tspan dy=\"40px\" dx=\"-60px\">K</tspan>";
    }
    if(value == 7){
        return "1M";
    }
    if(value == 8){
        return "10M";
    }
    if(value == 9){
        return "<tspan dy=\"-18px\" dx=\"4px\">100</tspan><tspan dy=\"40px\" dx=\"-60px\">M</tspan>";
    }
    if(value == 10){
        return "1B";
    }
    if(value == 11){
        return "10B";
    }
    return "";
}
inline fun buildAchievementTypeForSvg(value: Int): String{
    if(value <= 0x10){
        return "POSTS";
    }
    if(value <= 0x20){
        return "LIKES";
    }
    if(value <= 0x30){
        return "COMMENT";
    }
    if(value <= 0x40){
        return "FOLLOWERS";
    }
    return "";
}
// Generate SVG image with custom data
inline extends fun buildImage(self: IndividualContentAchivement, index: Int): String{
    let builder = beginString()
    .concat("<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 512 512\"><path fill=\"#646d73\" d=\"M359.8 429.3c.9 1.8 1.2 3.6 1.2 5.7v62H151V435c0-2.1.3-3.9 1.2-5.7l103.8-30 103.8 30Z\"/><path fill=\"#474f54\" d=\"M361 497v-62c0-2.1-.3-3.9-1.199-5.7L256 399.3V497z\"/><path fill=\"#fed843\" d=\"M482 60H419.1c-4 50.1-14.8 102.1-37.2 146.7C438.5 193.9 482 143.4 482 83ZM30 83c0 60.4 43.5 111 100.1 123.7C107.5 162.1 96.8 109.6 92.9 60H30V83ZM497 30c8.3 0 15 6.7 15 15V83c0 83.7-67 151.7-149.6 156.2-17.3 23.7-37.8 41.3-61.1 51.2 3.6 73.2 45 123.6 55.2 134.1 1.5 1.2 2.7 3 3.3 4.8H152.2c.6-1.8 1.8-3.6 3.3-4.8 9.9-10.5 51.6-61.2 55.2-134.1-23.2-9.9-43.7-27.5-60.9-51.2C67.1 234.8 0 166.8 0 83V45c0-8.3 6.7-15 15-15H91.6c-.1-5.1-.6-9.8-.6-15 0-8.4 6.6-15 15-15H406c8.4 0 15 6.6 15 15 0 5.2-.5 9.9-.6 15H497Z\"/><path fill=\"#fabe2c\" d=\"M279.9 190.8c5.1 2.6 11.2 2.1 15.7-1.2a15 15 0 006-14.6l-4.4-26.6 19.2-18.9a14.9 14.9 0 003.8-15.3 15 15 0 00-12-10.2l-26.7-4-12.1-24.1c-5.1-10.2-21.7-10.2-26.8 0l-12.1 24.1-26.7 4a15 15 0 00-12 10.2c-1.7 5.2-.4 11.3 3.8 15.3l19.2 18.9-4.4 26.6a15 15 0 006 14.6c4.6 3.3 10.7 3.8 15.7 1.2L256 178.4l23.9 12.4ZM482 60H419.1c-3.9 50.1-14.7 102.1-37.2 146.7C438.5 193.9 482 143.4 482 83Zm15-30c8.3 0 15 6.7 15 15V83c0 83.7-67 151.7-149.6 156.2-17.2 23.7-37.8 41.3-61.1 51.2 3.6 73.2 45 123.6 55.2 134.1 1.5 1.2 2.7 3 3.3 4.8H256V0H406c8.4 0 15 6.6 15 15 0 5.2-.5 9.9-.6 15H497Z\"/><path fill=\"#ff9100\" d=\"M256 178.5V68.3c5.4 0 10.9 2.5 13.4 7.6L281.5 100l26.7 4a15 15 0 0112 10.2 14.9 14.9 0 01-3.8 15.3l-19.2 18.9 4.4 26.6a15 15 0 01-6 14.6c-4.5 3.3-10.6 3.8-15.7 1.2Z\"/><path fill=\"#474f54\" d=\"M376 512H136c-8.3 0-15-6.7-15-15s6.7-15 15-15h240c8.3 0 15 6.7 15 15s-6.7 15-15 15z\"/><path fill=\"#32393f\" d=\"M376 482H256v30h120c8.291 0 15-6.709 15-15s-6.709-15-15-15z\"/>")
    .concat("<text fill=\"#fff\" x=\"210\" y=\"155\" style=\"font: bold 50px san-serif\" textLength=\"17%\">").concat(buildCountersTextForSvg(self.type)).concat("</text>")
    .concat("<text fill=\"#fff\" x=\"160\" y=\"470\" style=\"font: italic 37px san-serif\" textLength=\"37%\">").concat(buildAchievementTypeForSvg(self.type))
    .concat("</text></svg>");
    return builder.toString();
}