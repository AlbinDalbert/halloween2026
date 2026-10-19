defmodule Halloween.Starter do
  @moduledoc "Decks to start from. Loaded from the Decks page; edit them like any other."
  alias Halloween.{Card, Deck, Game}

  def load do
    for {name, description, card_attrs, texts} <- decks(Halloween.Text.language()) do
      {:ok, deck} = Game.save_deck(%Deck{}, %{name: name, description: description})

      for text <- texts do
        attrs =
          if is_map(text), do: Map.merge(card_attrs, text), else: Map.put(card_attrs, :text, text)

        {:ok, _} = Game.save_card(%Card{}, Map.put(attrs, :deck_id, deck.id))
      end
    end
  end

  defp decks("en") do
    [
      {"Pekleken", "Everyone points at someone at once.",
       %{audience: "everyone", input: "pick_guest", reveal: "tally"},
       [
         "Who would die first in a horror movie?",
         "Who would survive until the end credits?",
         "Who would go into the basement alone to check on the noise?",
         "Who is secretly a vampire?",
         "Who would {guest} trust to help hide a body?",
         "Who would sell everyone out to the monster?",
         "Who would befriend the ghost instead of running?",
         "Who would read the cursed book out loud?",
         "Who has the most chaotic search history?",
         "Who would be the last to notice they're in a horror movie?",
         "Who would still be dancing at 4 am?",
         "Who would be the best cult leader?",
         "Who would {guest} call to get rid of a spider?",
         "Who would turn into a zombie and not notice?"
       ]},
      {"Secret missions", "Dealt privately. Do it without getting caught, then tap I did it.",
       %{audience: "personal", input: "button", reveal: "tally", points: 2},
       [
         "Get {guest} to say the word \"pumpkin\".",
         "Make {guest} laugh out loud without telling a joke.",
         "Get {guest} to give you a high five.",
         "Swap seats with {guest} without them noticing why.",
         "Get three people to howl at the same time.",
         "Convince {guest} that you've seen a ghost in this house.",
         "Get {guest} to tell you their biggest fear.",
         "Use the word \"spooky\" five times in one conversation without anyone commenting.",
         "Get {guest} to compliment your costume.",
         "Start a toast and get at least four people to join in.",
         "Get {guest} to do an impression of a monster.",
         "Hide something that belongs to {guest} and let them find it within 10 minutes."
       ]},
      {"Halloween trivia", "Multiple choice against the clock. A point per right answer.",
       %{audience: "everyone", input: "pick_option", reveal: "tally", points: 1, seconds: 20},
       [
         %{
           text: "Halloween grew out of Samhain, a festival from which country?",
           options: ["Ireland", "Mexico", "Germany", "Romania"],
           correct: "Ireland"
         },
         %{
           text: "Before pumpkins, what did people in Ireland carve jack-o'-lanterns from?",
           options: ["Turnips", "Apples", "Potatoes", "Melons"],
           correct: "Turnips"
         },
         %{
           text: "Who wrote Frankenstein?",
           options: ["Mary Shelley", "Bram Stoker", "Edgar Allan Poe", "H. P. Lovecraft"],
           correct: "Mary Shelley"
         },
         %{
           text: "Bran Castle, sold as Dracula's castle, is in which country?",
           options: ["Romania", "Hungary", "Slovakia", "Serbia"],
           correct: "Romania"
         },
         %{
           text: "What is the fear of Halloween called?",
           options: ["Samhainophobia", "Coulrophobia", "Hallophobia", "Phasmophobia"],
           correct: "Samhainophobia"
         },
         %{
           text: "Which film has the line \"Here's Johnny!\"?",
           options: ["The Shining", "Psycho", "Halloween", "The Exorcist"],
           correct: "The Shining"
         },
         %{
           text: "What is a group of crows called?",
           options: ["A murder", "A coven", "A parliament", "A haunting"],
           correct: "A murder"
         },
         %{
           text: "What is the masked killer in the 1978 film Halloween called?",
           options: ["Michael Myers", "Jason Voorhees", "Freddy Krueger", "Ghostface"],
           correct: "Michael Myers"
         },
         %{
           text: "Botanically, a pumpkin is a…",
           options: ["Berry", "Vegetable", "Nut", "Root"],
           correct: "Berry"
         },
         %{
           text: "Harry Houdini died on which day?",
           options: ["Halloween", "Christmas Eve", "Friday the 13th", "New Year's Eve"],
           correct: "Halloween"
         }
       ]},
      {"Costume contest", "Everyone votes. The winner takes the points.",
       %{audience: "everyone", input: "pick_guest", reveal: "winner", points: 3},
       [
         "Best costume",
         "Scariest costume",
         "Most effort for the least result",
         "Costume you'd most like to steal"
       ]},
      {"Hot takes", "Rate it from 1 to 10.",
       %{audience: "everyone", input: "scale", reveal: "tally"},
       [
         "Candy corn is actually good.",
         "Horror movies are better than comedies.",
         "How scared would you be alone in a graveyard at midnight?",
         "Rate {guest}'s costume.",
         "How likely are you to believe in ghosts by the end of tonight?"
       ]},
      {"Never have I ever", "Tap if you have. Everyone sees who did.",
       %{audience: "everyone", input: "button", reveal: "list", options: ["I have"]},
       [
         "Never have I ever walked out of a horror movie.",
         "Never have I ever slept with the lights on after a scary movie.",
         "Never have I ever eaten the trick-or-treat candy before any kids came.",
         "Never have I ever screamed at a jump scare in a cinema.",
         "Never have I ever reused a costume.",
         "Never have I ever pretended a house was haunted to scare someone."
       ]},
      {"Confessions", "Everyone writes. Answers are shown without names.",
       %{audience: "everyone", input: "text", reveal: "anonymous"},
       [
         "Your most irrational fear.",
         "The worst costume you've ever worn.",
         "Describe {guest} in three words.",
         "The scariest thing that has actually happened to you.",
         "What monster would you be, and why?"
       ]},
      {"Photo hunt", "Everyone sends a photo. They show up together on the TV.",
       %{audience: "everyone", input: "photo", reveal: "list"},
       [
         "Your best scared face.",
         "A selfie with {guest}.",
         "Something orange.",
         "Recreate a horror movie poster with at least two people.",
         "The spookiest corner of this house."
       ]}
    ]
  end

  defp decks("sv") do
    [
      {"Pekleken", "Alla pekar på någon samtidigt.",
       %{audience: "everyone", input: "pick_guest", reveal: "tally"},
       [
         "Vem skulle dö först i en skräckfilm?",
         "Vem skulle överleva ända till eftertexterna?",
         "Vem skulle gå ner ensam i källaren för att kolla vad det var som lät?",
         "Vem är egentligen en vampyr?",
         "Vem skulle {guest} lita på för att gömma ett lik?",
         "Vem skulle sälja ut alla till monstret?",
         "Vem skulle bli kompis med spöket i stället för att springa?",
         "Vem skulle läsa högt ur den förbannade boken?",
         "Vem har den mest kaotiska sökhistoriken?",
         "Vem skulle vara sist med att fatta att hen är med i en skräckfilm?",
         "Vem dansar fortfarande klockan fyra på morgonen?",
         "Vem skulle bli den bästa sektledaren?",
         "Vem skulle {guest} ringa för att bli av med en spindel?",
         "Vem skulle bli zombie utan att märka det?"
       ]},
      {"Hemliga uppdrag",
       "Delas ut i hemlighet. Gör det utan att åka fast, och tryck sedan på Klart!",
       %{audience: "personal", input: "button", reveal: "tally", points: 2},
       [
         "Få {guest} att säga ordet \"pumpa\".",
         "Få {guest} att skratta högt utan att du drar ett skämt.",
         "Få {guest} att ge dig en high five.",
         "Byt plats med {guest} utan att hen förstår varför.",
         "Få tre personer att yla samtidigt.",
         "Övertyga {guest} om att du har sett ett spöke i det här huset.",
         "Få {guest} att berätta vad hen är mest rädd för.",
         "Säg \"läskigt\" fem gånger i samma samtal utan att någon kommenterar det.",
         "Få {guest} att ge dig en komplimang för din utklädnad.",
         "Utbringa en skål och få minst fyra personer att hänga på.",
         "Få {guest} att härma ett monster.",
         "Göm något som tillhör {guest} och låt hen hitta det inom tio minuter."
       ]},
      {"Halloweenquiz", "Flera svarsalternativ, mot klockan. En poäng per rätt svar.",
       %{audience: "everyone", input: "pick_option", reveal: "tally", points: 1, seconds: 20},
       [
         %{
           text: "Halloween växte fram ur Samhain, en högtid från vilket land?",
           options: ["Irland", "Mexiko", "Tyskland", "Rumänien"],
           correct: "Irland"
         },
         %{
           text: "Vad karvade man lyktor av på Irland innan pumporna?",
           options: ["Kålrötter", "Äpplen", "Potatis", "Meloner"],
           correct: "Kålrötter"
         },
         %{
           text: "Vem skrev Frankenstein?",
           options: ["Mary Shelley", "Bram Stoker", "Edgar Allan Poe", "H. P. Lovecraft"],
           correct: "Mary Shelley"
         },
         %{
           text: "Bran Castle, som säljs in som Draculas slott, ligger i vilket land?",
           options: ["Rumänien", "Ungern", "Slovakien", "Serbien"],
           correct: "Rumänien"
         },
         %{
           text: "Vad kallas rädsla för halloween?",
           options: ["Samhainofobi", "Koulrofobi", "Hallofobi", "Fasmofobi"],
           correct: "Samhainofobi"
         },
         %{
           text: "Vilken film har repliken \"Here's Johnny!\"?",
           options: ["The Shining", "Psycho", "Halloween", "Exorcisten"],
           correct: "The Shining"
         },
         %{
           text: "Vilken svensk film från 2008 handlar om en vampyrflicka i Blackeberg?",
           options: ["Låt den rätte komma in", "Gräns", "Midsommar", "Vargtimmen"],
           correct: "Låt den rätte komma in"
         },
         %{
           text: "Vad heter den maskerade mördaren i filmen Halloween från 1978?",
           options: ["Michael Myers", "Jason Voorhees", "Freddy Krueger", "Ghostface"],
           correct: "Michael Myers"
         },
         %{
           text: "Botaniskt sett är en pumpa ett…",
           options: ["Bär", "Grönsak", "Nöt", "Rotfrukt"],
           correct: "Bär"
         },
         %{
           text: "Vilken dag dog Harry Houdini?",
           options: ["Halloween", "Julafton", "Fredag den 13:e", "Nyårsafton"],
           correct: "Halloween"
         }
       ]},
      {"Maskeradtävling", "Alla röstar. Vinnaren tar poängen.",
       %{audience: "everyone", input: "pick_guest", reveal: "winner", points: 3},
       [
         "Bästa utklädnaden",
         "Läskigaste utklädnaden",
         "Mest möda för minst resultat",
         "Utklädnaden du helst skulle sno"
       ]},
      {"Heta åsikter", "Betygsätt från 1 till 10.",
       %{audience: "everyone", input: "scale", reveal: "tally"},
       [
         "Salt lakrits är det godaste godiset som finns.",
         "Skräckfilm är bättre än komedi.",
         "Hur rädd skulle du vara ensam på en kyrkogård vid midnatt?",
         "Betygsätt utklädnaden som {guest} har.",
         "Hur troligt är det att du tror på spöken när kvällen är slut?"
       ]},
      {"Jag har aldrig", "Tryck om du har gjort det. Alla ser vem som har det.",
       %{audience: "everyone", input: "button", reveal: "list", options: ["Det har jag"]},
       [
         "Jag har aldrig gått ut mitt under en skräckfilm.",
         "Jag har aldrig sovit med lampan tänd efter en läskig film.",
         "Jag har aldrig ätit upp godiset innan barnen hann knacka på.",
         "Jag har aldrig skrikit högt på bio för en jump scare.",
         "Jag har aldrig använt samma utklädnad två gånger.",
         "Jag har aldrig låtsats att ett hus var hemsökt för att skrämma någon."
       ]},
      {"Bekännelser", "Alla skriver. Svaren visas utan namn.",
       %{audience: "everyone", input: "text", reveal: "anonymous"},
       [
         "Din mest irrationella rädsla.",
         "Den sämsta utklädnaden du någonsin har haft.",
         "Beskriv {guest} med tre ord.",
         "Det läskigaste som faktiskt har hänt dig.",
         "Vilket monster skulle du vara, och varför?"
       ]},
      {"Fotojakt", "Alla skickar ett foto. De visas tillsammans på tv:n.",
       %{audience: "everyone", input: "photo", reveal: "list"},
       [
         "Ditt bästa rädda ansikte.",
         "En selfie med {guest}.",
         "Något orange.",
         "Återskapa en skräckfilmsaffisch med minst två personer.",
         "Det läskigaste hörnet i det här huset."
       ]}
    ]
  end
end
