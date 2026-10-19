defmodule Halloween.Text.Swedish do
  @moduledoc """
  The Swedish for every English text in the app, for `Halloween.Text.t/2`. Keys are the English
  exactly as written in the code. `Halloween.TextTest` fails when one is missing.
  """

  def strings do
    %{
      # Cards
      "For your eyes only" => "Bara för dina ögon",
      "Your challenge" => "Ditt uppdrag",
      "Point at someone" => "Peka på någon",
      "Choose one" => "Välj ett",
      "Write it down" => "Skriv ner det",
      "From 1 to 10" => "Från 1 till 10",
      "Take a photo" => "Ta ett foto",
      "Hands up" => "Upp med handen",
      "1 point" => "1 poäng",
      "%{n} points" => "%{n} poäng",
      "%{n} pts" => "%{n} p",
      "Me!" => "Jag!",

      # Results
      "%{n} of %{total} answered" => "%{n} av %{total} har svarat",
      "Nobody answered." => "Ingen svarade.",
      "Photo by %{name}" => "Foto av %{name}",
      "Average" => "Snitt",
      "Someone who left" => "Någon som har gått",
      "1 vote" => "1 röst",
      "%{n} votes" => "%{n} röster",
      "Standings" => "Ställning",

      # The door
      "At the door" => "Vid dörren",
      "Still picking a name" => "Väljer fortfarande namn",
      "Let in" => "Släpp in",
      "Turn away %{name}?" => "Visa bort %{name}?",
      "Turn away" => "Visa bort",
      "You were turned away at the door." => "Du blev bortvisad vid dörren.",
      "You knocked" => "Du har knackat på",
      "%{name}, wait at the door" => "%{name}, vänta vid dörren",
      "A host will let you in. This page opens by itself when they do." =>
        "En värd släpper snart in dig. Sidan öppnar sig själv när hen gör det.",
      "Someone is at the door. Let them in →" => "Någon står vid dörren. Släpp in →",
      "%{n} people are at the door. Let them in →" => "%{n} personer står vid dörren. Släpp in →",

      # Logging in
      "The Halloween Table" => "Halloweenbordet",
      "You are invited to" => "Du är bjuden till",
      "Take your seat" => "Ta plats",
      "Login isn't set up: OIDC_ISSUER, OIDC_CLIENT_ID or OIDC_CLIENT_SECRET is missing." =>
        "Inloggningen är inte inställd: OIDC_ISSUER, OIDC_CLIENT_ID eller OIDC_CLIENT_SECRET saknas.",
      "Couldn't reach the login provider. Try again." =>
        "Fick ingen kontakt med inloggningen. Försök igen.",
      "Login didn't work. Try again." => "Inloggningen misslyckades. Försök igen.",
      "Log out" => "Logga ut",

      # A guest's phone
      "Your cards" => "Dina kort",
      "Who goes there?" => "Vem där?",
      "Change your name or sigil" => "Byt namn eller symbol",
      "Change your name" => "Byt namn",
      "Your name, as the others know you" => "Ditt namn, som de andra känner dig",
      "Your sigil" => "Din symbol",
      "Answers are closed for this card." => "Det här kortet tar inte emot fler svar.",
      "Locked in. You can change it until answers close." =>
        "Låst. Du kan ändra dig tills svaren stängs.",
      "Answers are closed. Eyes on the TV." => "Svaren är stängda. Titta på tv:n.",
      "No cards yet. The host deals them during the night." =>
        "Inga kort än. Värden delar ut dem under kvällen.",
      "Tap to seal it again" => "Tryck för att försegla det igen",
      "Sealed. Tap to read it in secret." => "Förseglat. Tryck för att läsa i hemlighet.",
      "Waiting for the host to confirm" => "Väntar på att värden ska godkänna",
      "Done" => "Klart",
      "I did it" => "Klart!",
      "Host controls" => "Värdens kontroller",
      "Write here" => "Skriv här",
      "Change answer" => "Ändra svar",
      "Send" => "Skicka",
      "Sent. You can change it until answers close." =>
        "Skickat. Du kan ändra dig tills svaren stängs.",
      "Your photo" => "Ditt foto",
      "Take another" => "Ta ett nytt",
      "Uploading %{n}%" => "Laddar upp %{n} %",
      "Send photo" => "Skicka foto",
      "That photo is too big (20 MB max)." => "Fotot är för stort (max 20 MB).",
      "That file isn't a photo we can show." => "Den filen är inte ett foto som går att visa.",
      "The photo didn't upload. Try again." => "Fotot laddades inte upp. Försök igen.",

      # The TV
      "TV" => "TV",
      "Answers are in…" => "Svaren är inne…",
      "Scan to take your seat" => "Skanna för att ta plats",

      # Host pages
      "Host" => "Värd",
      "Live" => "Live",
      "Decks" => "Kortlekar",
      "Guests" => "Gäster",
      "My phone" => "Min telefon",
      "On stage" => "På scen",
      "Close answers" => "Stäng svaren",
      "Reveal" => "Visa svaren",
      "Next card" => "Nästa kort",
      "Clear stage" => "Töm scenen",
      "Only you see this until you reveal it." => "Bara du ser det här tills du visar svaren.",
      "Nothing on stage. Draw a card from a deck below, and every phone and the TV will show it." =>
        "Inget på scen. Dra ett kort ur en kortlek nedan, så visas det på alla telefoner och på tv:n.",
      "Guests' cards" => "Gästernas kort",
      "Approve" => "Godkänn",
      "Reject" => "Neka",
      "Discard" => "Släng",
      "No decks yet." => "Inga kortlekar än.",
      "Make one, or load the starter decks." => "Gör en, eller hämta startlekarna.",
      "%{n} cards" => "%{n} kort",
      "Draw" => "Dra",
      "Deal a card from %{deck} to every guest?" =>
        "Dela ut ett kort ur %{deck} till alla gäster?",
      "Deal to everyone" => "Dela ut till alla",
      "Pick a card" => "Välj ett kort",
      "Play" => "Spela",
      "Guest" => "Gäst",
      "Give" => "Ge",
      "Give points" => "Ge poäng",
      "What for" => "För vad",
      "Dealt a card to %{n} guests." => "Delade ut ett kort till %{n} gäster.",
      "Dealt to %{name}." => "Utdelat till %{name}.",
      "Points must be a whole number." => "Poängen måste vara ett heltal.",
      "That deck has no cards for this." => "Den kortleken har inga kort för det här.",
      "Couldn't do that: %{reason}" => "Det gick inte: %{reason}",

      # Guests page
      "You can't stop being a host yourself." => "Du kan inte sluta vara värd själv.",
      "Nobody has taken a seat yet. Put the TV on: it shows a code to scan." =>
        "Ingen har tagit plats än. Sätt på tv:n, där finns en kod att skanna.",
      "Remove host" => "Ta bort som värd",
      "Make host" => "Gör till värd",
      "Remove %{name}, with their answers and points?" =>
        "Ta bort %{name}, med alla svar och poäng?",
      "Remove" => "Ta bort",

      # Decks
      "Starter decks loaded." => "Startlekarna är hämtade.",
      "A deck is a pile of cards: one game, like Pekleken or trivia. Start from the starter decks, or make your own." =>
        "En kortlek är en hög kort: ett spel, som Pekleken eller quiz. Börja med startlekarna, eller gör egna.",
      "Load the starter decks" => "Hämta startlekarna",
      "Add the starter decks next to the decks you already have?" =>
        "Lägga till startlekarna bredvid de kortlekar du redan har?",
      "New deck" => "Ny kortlek",
      "Name" => "Namn",
      "What it's about (only you see this)" => "Vad den handlar om (bara du ser det)",
      "Create deck" => "Skapa kortlek",
      "Deck saved." => "Kortleken är sparad.",
      "Card saved." => "Kortet är sparat.",
      "Deck" => "Kortlek",
      "What it's about" => "Vad den handlar om",
      "Save" => "Spara",
      "Edit card" => "Redigera kort",
      "New card" => "Nytt kort",
      "Cards" => "Kort",
      "No cards yet. Write the first one above." => "Inga kort än. Skriv det första ovanför.",
      "Edit" => "Redigera",
      "Delete this card?" => "Radera kortet?",
      "Delete" => "Radera",
      "Delete %{deck} and all its cards?" => "Radera %{deck} och alla dess kort?",
      "Delete deck" => "Radera kortleken",

      # The card form
      "Card text" => "Kortets text",
      "Who would {guest} trust to hide a body?" =>
        "Vem skulle {guest} lita på för att gömma ett lik?",
      "Write" => "Skriv",
      "and it becomes a random guest's name when the card is played." =>
        "så blir det en slumpad gästs namn när kortet spelas.",
      "Who gets it" => "Vem får det",
      "Everyone, on stage" => "Alla, på scen",
      "One guest, privately" => "En gäst, i hemlighet",
      "How they answer" => "Hur de svarar",
      "Choices, one per line" => "Alternativ, ett per rad",
      "Right answer" => "Rätt svar",
      "No right answer" => "Inget rätt svar",
      "Button text" => "Text på knappen",
      "How the answers are revealed" => "Hur svaren visas",
      "Time limit in seconds" => "Tidsgräns i sekunder",
      "None" => "Ingen",
      "Points" => "Poäng",
      "Save card" => "Spara kortet",
      "Add card" => "Lägg till kortet",
      "Cancel" => "Avbryt",
      "A challenge: they tap \"I did it\"" => "Ett uppdrag: de trycker på \"Klart!\"",
      "A secret: just for them to read" => "En hemlighet: bara för dem att läsa",
      "Point at a guest" => "Peka på en gäst",
      "Multiple choice" => "Flera svarsalternativ",
      "Write something" => "Skriv något",
      "Rate from 1 to 10" => "Betygsätt från 1 till 10",
      "Tap a button" => "Tryck på en knapp",
      "No answer, just show it" => "Inget svar, bara visa det",
      "Bar chart, with who picked what" => "Stapeldiagram, med vem som valde vad",
      "Only the winner" => "Bara vinnaren",
      "Every answer, with names" => "Alla svar, med namn",
      "Every answer, no names" => "Alla svar, utan namn",
      "They get the points when you approve the challenge." =>
        "De får poängen när du godkänner uppdraget.",
      "The most picked guest gets the points when you reveal." =>
        "Gästen som fick flest röster får poängen när du visar svaren.",
      "Everyone who picks the right answer gets the points." =>
        "Alla som väljer rätt svar får poängen.",
      "Nobody gets these automatically. Give points by hand from Live." =>
        "Ingen får dem automatiskt. Ge poäng för hand under Live.",
      "Private" => "Privat",

      # Form errors (from Ecto and the card's rules)
      "can't be blank" => "måste fyllas i",
      "is invalid" => "är ogiltigt",
      "should be at most %{count} character(s)" => "får vara högst %{count} tecken",
      "must be greater than %{number}" => "måste vara större än %{number}",
      "must be greater than or equal to %{number}" => "måste vara minst %{number}",
      "needs at least two options" => "behöver minst två alternativ",
      "must be one of the options" => "måste vara ett av alternativen",
      "must be a challenge or a secret for a personal card" =>
        "måste vara ett uppdrag eller en hemlighet för ett personligt kort"
    }
  end
end
