defmodule Halloween.Starter do
  @moduledoc "Decks to start from. Loaded from the Decks page; edit them like any other."
  alias Halloween.{Card, Deck, Game}

  def load do
    for {name, description, card_attrs, texts} <- decks() do
      {:ok, deck} = Game.save_deck(%Deck{}, %{name: name, description: description})

      for text <- texts do
        attrs =
          if is_map(text), do: Map.merge(card_attrs, text), else: Map.put(card_attrs, :text, text)

        {:ok, _} = Game.save_card(%Card{}, Map.put(attrs, :deck_id, deck.id))
      end
    end
  end

  defp decks do
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
end
