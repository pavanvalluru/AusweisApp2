/*!
 * \brief Parse information for DidAuthenticateEacAdditional.
 *
 * \copyright Copyright (c) 2014 Governikus GmbH & Co. KG
 */

#pragma once

#include "paos/PaosMessage.h"
#include "paos/retrieve/DidAuthenticateEacAdditional.h"
#include "paos/retrieve/PaosParser.h"

#include <QScopedPointer>
#include <QString>


namespace governikus
{

class DidAuthenticateEacAdditionalParser
	: public PaosParser
{
	public:
		DidAuthenticateEacAdditionalParser();
		~DidAuthenticateEacAdditionalParser();

	protected:
		virtual PaosMessage* parseMessage() override;

	private:
		QString parseEacAdditionalInputType();

	private:
		QScopedPointer<DIDAuthenticateEACAdditional> mDidAuthenticateEacAdditional;
};

} /* namespace governikus */
