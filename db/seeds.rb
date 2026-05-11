newspaper = Newspaper.find_or_create_by!(name: "Pryce of Progress")
newspaper.update!(
  tagline:        "What the Tribune Will Not Tell You — Twice a Week, Sometimes Thrice",
  print_location: "Printed in Bosum Strand"
)

edition = newspaper.editions.find_or_create_by!(volume: 2, issue_number: 98) do |e|
  e.year          = 501
  e.season        = :spring
  e.day           = 10
  e.attention_bar = "♦ The Workingman's Friend · Truth in Spite of Power · What the Tribune Won't Tell You ♦"
  e.published     = true
end
edition.update!(
  edition_type: "Extra Edition",
  price:        "Two Pennies",
  city:         "Flint"
)

stories = [
  {
    story_type:     :major,
    position:       1,
    headline:       "Zero Arrests. Several Funerals.",
    supertitle:     "Operation Mercury · Day One · Tenth of Spring, 501",
    subtitle:       "The Guild Knew They Were Coming. We Have Thoughts on Why.",
    summary_ticker: "Officers Killed — Twice as Many Wounded — The RHC: \"Progress Is Being Made\"",
    author:         "Bartholomew Pryce",
    quote:          "The Theater of Scoundrels. That is what it is called. The RHC knew this. They were still surprised.",
    quote_origin:   nil,
    body: <<~BODY
      The Royal Homeland Constabulary is, by its own account, the sharpest instrument of law enforcement the Crown of Risur has ever produced. It is staffed by the finest investigators money and prestige can attract. It reports directly to the King. It has a crest. It has a motto. It has, this paper is reliably informed, very nice offices.

      It has also, in a single day of operation against a criminal organisation headquartered in a theatre, managed to get several Flint policemen killed, twice as many wounded, zero criminals arrested, and every one of its targets forewarned, fortified, and apparently in better tactical shape at the end of the day than at the beginning. The Kell Guild, which runs its affairs from a building with the word "Scoundrels" in the name, outmaneuvered the Crown's finest before breakfast.

      We are told the operation was managed from RHC headquarters. We believe it. The headquarters is a fine building, well-heated, far from Parity Lake, and entirely free of the barricades that were waiting for the officers the RHC sent in its stead. Those officers — Flint men and women, every one — walked through doors that the Guild had been expecting them to walk through for some time. Three were killed at a warehouse on Coalbridge Lane before they had finished coming through the frame. Two more died in a laneway ambush off Stanfield Row, caught in a crossfire between positions that had been prepared, by any reasonable estimate, hours before the task force left its staging point.

      The staging point, we should note, was an open hall. The briefing was conducted by officers of the RHC to some fifty men and women of the Flint City Police. The operation's name, its targets, and its timetable were shared aloud in a room whose security arrangements this paper would charitably describe as aspirational. Three of the fifty officers in that room were drawn from districts where Kell's influence is not merely present but foundational — districts where the Guild collects rents, settles disputes, and employs men's cousins. The RHC did not, apparently, consider this a concern.

      This paper has a theory. It is not a complicated theory. It is, in fact, so simple that we are embarrassed on behalf of the RHC that it apparently did not occur to them. When you announce an operation publicly, brief it in an open hall, and staff your task force with officers drawn from the districts your target controls — your target finds out. This is not espionage. This is not dark magic. This is the consequence of being, in the most charitable possible terms, breathtakingly naive.

      In less charitable terms, which this paper is also prepared to offer: it is incompetence of a calibre that would embarrass a moderately clever dog. The RHC has Crown funding, Crown authority, and the full apparatus of the state behind it. Lorcan Kell has a theatre and some hired muscle. Yesterday, Lorcan Kell won.

      The RHC has described this as a foundation for future progress. We await that progress with the patience of men who have learned, through long experience, not to expect very much from institutions that describe catastrophe as a learning opportunity. The officers who died yesterday did not die learning. They died because the men who sent them did not think it necessary to keep the plan secret from the people it was designed to surprise.

      Flowers have been sent to the families of the dead. We did not wait to be asked. We felt that, between our gesture and the RHC's press statement, ours was the one more likely to be of comfort.
    BODY
  },
  {
    story_type:     :secondary,
    position:       2,
    headline:       "Children Missing in the Woods",
    supertitle:     "The Cloudwood · A Story Nobody Else Is Covering",
    subtitle:       nil,
    summary_ticker: nil,
    author:         "Hettie Crow",
    quote:          "It's not wolves. Wolves leave something behind.",
    quote_origin:   "A father in the Cloudwood district, who did not wish his name printed",
    body: <<~BODY
      Marta Ossel's daughter is eight years old. She went into the Cloudwood on the twenty-second of Winter to gather kindling — as she had done every week of her life — and did not come back. The Flint police took a report. No one has returned to follow up. That was forty-seven days ago.

      Marta Ossel is not alone. This correspondent spent two days in the Cloudwood district and spoke with eleven families. Six are missing children. Two are missing adults — in both cases, parents who went into the deep wood to search for their sons and did not return. The remaining three families reported neighbours whose children have vanished in the past two months and who have since moved away from the district entirely, unwilling to stay.

      In every case the police report exists. In every case the follow-up does not.

      The Cloudwood has always carried a reputation. The fey are near. The light comes strange through the canopy, particularly past the third mile where the old growth closes overhead and the paths become less certain. Sensible residents stay to the known trails, teach their children the markers, and do not go out after dark in the deep months of winter. These are not credulous people. They have lived beside the wood their entire lives. They know what is ordinary and what is not.

      What is happening now, they say, is not ordinary.

      The disappearances follow no pattern this correspondent can identify. The children range in age from six to fourteen. They vanished on different days, in different parts of the district, in conditions ranging from bright afternoon to dusk. No bodies have been found. No clothing. No signs of struggle. The families describe it the same way, independently, without coordination: the child went out. The child did not come back. There was nothing to find.

      One father, who spoke on condition that his name not be printed, put it plainly enough. He has been into the deep wood four times searching for his son. He found no tracks, no cloth, no blood. The wood, he said, was simply quiet.

      With the city's constabulary reassigned to Operation Mercury and the harbour watch stretched to breaking, the Cloudwood district has no police presence to speak of. The families this correspondent spoke with understand that the city has other concerns. They understand that Lorcan Kell and the Pardwight terror and the peace summit and the harbour are, in the official calculus, more urgent. They do not dispute this. They merely ask — and they ask it quietly, because they are people accustomed to not being heard — whether someone might find time to look before more of their children do not come home.

      This paper adds its voice to theirs. We do not know what is taking the children of the Cloudwood. We know only that something is, and that no one with authority appears to have noticed.
    BODY
  },
  {
    story_type:     :tertiary,
    position:       3,
    headline:       "Rackus Reads to the Children",
    supertitle:     "A Dispatch from the Cultural Front",
    subtitle:       "The city's most celebrated accidental killer begins his community service. The orphans were not consulted.",
    summary_ticker: nil,
    author:         "A Penny Honest Man",
    quote:          "The kids asked for an encore. What am I gonna do?",
    quote_origin:   "Rock Rackus, through the front gate of the Sisters of Mercy Home for Foundlings",
    body: <<~BODY
      Rock Rackus — docker, balladeer, convicted killer, and certified hero of the people, all of which he has managed within the same calendar month — has begun his court-mandated community service at the Stanfield Canal Orphanage and the Sisters of Mercy Home for Foundlings in Parity Lake.

      The service, handed down by Magistrate Fenn in lieu of further custodial time, requires Mr. Rackus to read improving literature to children for twelve hours per week across six weeks. The improving literature was selected by the court and includes, we are told, volumes on civic responsibility, moral hygiene, and the lives of Risur's great statesmen. Magistrate Fenn has confirmed this was intended to be humbling.

      It has not been humbling.

      Mr. Rackus arrived at the Sisters of Mercy Home on the morning of the seventh with the court-mandated volumes under one arm and his guitar under the other. The guitar was not part of the sentence. By the second morning, a small crowd had gathered outside the orphanage. By the third, there was a queue. The improving literature, this correspondent is given to understand, was set aside within the first hour of the first day, after Mr. Rackus attempted to read aloud from 'The Moral Foundations of Civic Duty' and was informed by a six-year-old that it was boring.

      Mr. Rackus has since replaced the mandated reading material with his own compositions, performed from memory, to an audience of thirty-seven children aged four to fourteen who are, by every available account, enthralled. The performances include audience participation, call-and-response sections, and at least one ballad about a dragon that this correspondent suspects was composed on the spot. Three of the Sisters of Mercy were observed singing along during the chorus. No formal complaint has been filed by the orphanage. The Stanfield Canal Orphanage, visited separately, reported that the children have asked when Mr. Rackus is coming back. He is scheduled for Thursday.

      Magistrate Fenn has been notified of the deviation from the prescribed curriculum. His office has issued no formal response, which this correspondent interprets as either judicial restraint or quiet despair. The children, meanwhile, are understood to be threatening a collective action of some description if anyone attempts to take Mr. Rackus away before the six weeks are complete.

      This paper observes, with the fondness we reserve for things that are stupid and good, that Rock Rackus may be the only man in Flint whose court-mandated punishment has made him more popular than he was before he committed the crime.
    BODY
  },
  {
    story_type: :advertisement,
    position:   4,
    headline:   "Wife Wanted",
    body:       "Farmer, 43, of good character and moderate temperament, seeks wife. Must be willing to relocate to the Cloudwood district. Applicant should not be superstitious. Owns thirty-two goats, all named. Previous applicant withdrew for reasons the advertiser considers unreasonable. Enquiries to Mr. H. Botts, care of the Cloudwood Post Office, assuming it is still open."
  },
  {
    story_type: :advertisement,
    position:   5,
    headline:   "Steam-Press For Sale",
    body:       "One (1) Pemberton & Co. rotary steam-press, Model 14, lightly used. Slight fire damage to the left flywheel housing. Previously the property of the Flint Tribune. Vendor acquired the device lawfully from the rubble and is prepared to discuss this at length. Price negotiable. Will not deliver to Pardwight. Apply in writing to Box 19, Bosum Strand."
  },
  {
    story_type: :advertisement,
    position:   6,
    headline:   "Language Tutor Available",
    body:       "Graduate of Pardwight University (Second Class, Rhetoric & Classical Letters) offers private tuition in Classical Elvish, Introductory Draconic, and Conversational Danoran. Available most evenings. Currently displaced. Will travel to pupil's home provided it has not recently exploded. References available upon request. Rates: 3 silver per hour, reduced for orphans and constables' widows."
  },
  {
    story_type: :advertisement,
    position:   7,
    headline:   "Lost Dog",
    body:       "Missing since the Ninth of Spring: one brown terrier, answers to 'Sergeant.' Last seen near the Pardwight skywalk at approximately half past one, i.e. ninety minutes before the explosion, which the owner wishes to state clearly has nothing to do with the dog. Sergeant is friendly, has a torn left ear, and is not affiliated with any radical organisation. Reward of 5 silver. Apply to Mrs. Calloway, 14 Pensher Street, Bosum Strand."
  },
  {
    story_type: :advertisement,
    position:   8,
    headline:   "Rooms To Let — Pardwight",
    body:       "Handsome furnished rooms available at 9 Knothole Lane, Pardwight district. Ground floor. Excellent natural light owing to recent structural adjustments to the neighbouring building. Very quiet street. Neighbours have largely relocated. Rent reduced accordingly. Landlord willing to negotiate further in exchange for tenant who does not startle easily. No journalists."
  }
]

stories.each do |attrs|
  edition.stories.find_or_create_by!(headline: attrs[:headline]) do |s|
    s.assign_attributes(attrs)
  end
end

puts "Seeded: #{newspaper.name} — Vol. #{edition.volume}, No. #{edition.issue_number} (#{edition.stories.count} stories)"
