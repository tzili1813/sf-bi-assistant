/**
 * BIChatMessage
 * -------------
 * Simple DTO that travels between the LWC and Apex to represent one
 * message in the multi-turn conversation.  The LWC keeps the full list
 * client-side and sends it on every turn so the Models API can see the
 * complete context window.
 *
 * Roles follow the Models API convention:
 *   "system"    – the system/schema prompt (added server-side)
 *   "user"      – the human's question  (or injected result context)
 *   "assistant" – the LLM's reply
 */
public class BIChatMessage {
    @AuraEnabled public String role    { get; set; }
    @AuraEnabled public String content { get; set; }

    public BIChatMessage() {}

    public BIChatMessage(String role, String content) {
        this.role    = role;
        this.content = content;
    }
}
