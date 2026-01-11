import SwiftUI

struct UserProfileHeaderView: View {
    var profilePicture: ImageSizes?
    var fullName: String
    var onlineOrLastSeen: LocalizedStringKey?
    var ageAndPlace: LocalizedStringKey?

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            ProfilePictureView(profilePicture: profilePicture)
            ProfileHeaderInfoView(
                title: fullName,
                subheading: onlineOrLastSeen,
                additionalInfo: ageAndPlace,
            )
        }
    }
}

struct GroupProfileHeaderView: View {
    var profilePicture: ImageSizes?
    var name: String
    var groupKind: LocalizedStringKey
    var place: LocalizedStringKey?

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            ProfileHeaderInfoView(
                title: name,
                subheading: groupKind,
                additionalInfo: place,
            )
            ProfilePictureView(profilePicture: profilePicture)
        }
    }
}

private let profilePictureHeight: CGFloat = 85

private struct ProfilePictureView: View {
    var profilePicture: ImageSizes?

    @Environment(\.displayScale) private var displayScale

    var body: some View {
        UserProfilePictureView(
            location: profilePicture?
                .sizeThatFits(square: profilePictureHeight, scale: displayScale)
        )
        .frame(width: profilePictureHeight, height: profilePictureHeight)
        .aspectRatio(1, contentMode: .fit)
    }
}

private struct ProfileHeaderInfoView: View {
    var title: String
    var subheading: LocalizedStringKey?
    var additionalInfo: LocalizedStringKey?

    @EnvironmentObject private var palette: PaletteHolder

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(verbatim: title)
                .font(.title3)
                .fontWeight(.medium)
            if let subheading {
                Text(subheading)
                    .font(.callout)
                    .foregroundStyle(palette.grayText)
            }
            if let additionalInfo {
                Text(additionalInfo)
                    .font(.callout)
                    .foregroundStyle(palette.grayText)
                    .padding(.top)
            }
        }
        .alignmentGuide(VerticalAlignment.center) { d in
            // While the view fits the profile picture height, center-align it.
            // When it's too tall, use top alignment.
            let trueCenter = d[VerticalAlignment.center]
            return d.height < profilePictureHeight
                ? trueCenter
                : profilePictureHeight / 2
        }
        Spacer(minLength: 0)
        Button {
            /* TODO: Show profile information */
        } label: {
            Image(systemName: "info.circle")
        }
        .accessibilityLabel(
            Text("Information", comment: "User/group profile info button label")
        )
        .buttonStyle(.borderless)
        .tint(nil)
    }
}

@available(iOS 17.0, *)
#Preview("User profile header", traits: .sizeThatFitsLayout) {
    UserProfileHeaderView(
        profilePicture: nil, // TODO: Use picture
        fullName: "Boromir",
        onlineOrLastSeen: "last seen 5 minutes ago".excludedFromLocalization,
        ageAndPlace: "40 years, Gondor".excludedFromLocalization,
    )
    .environmentObject(PaletteHolder())
}

@available(iOS 17.0, *)
#Preview("User profile header with very long name", traits: .fixedLayout(width: 320, height: 640)) {
    UserProfileHeaderView(
        profilePicture: nil, // TODO: Use picture
        fullName: "Grzegorz Brzęczyszczykiewicz",
        onlineOrLastSeen: "online",
        ageAndPlace: "27 years, Chrząszczyżewoszyce powiat Łękołody".excludedFromLocalization,
    )
    .environmentObject(PaletteHolder())
}

@available(iOS 17.0, *)
#Preview("Group profile header", traits: .sizeThatFitsLayout) {
    GroupProfileHeaderView(
        profilePicture: nil, // TODO: Use picture
        name: "Birdwatchers of the Fediverse",
        groupKind: "open group",
        place: "Planet Earth".excludedFromLocalization,
    )
    .environmentObject(PaletteHolder())
}
